import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/extension_request.dart';
import '../repositories/session_repository.dart';
import '../repositories/message_repository.dart';

class ChatService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final SessionRepository _sessionRepository = SessionRepository();
  final MessageRepository _messageRepository = MessageRepository();
  final String userId;

  StreamSubscription<DatabaseEvent>? _messageSubscription;
  StreamSubscription<DatabaseEvent>? _sessionSubscription;

  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<List<ChatSession>> _sessionController =
      StreamController<List<ChatSession>>.broadcast();
  final StreamController<List<ExtensionRequest>> _extensionRequestController =
      StreamController<List<ExtensionRequest>>.broadcast();

  ChatService({required this.userId}) {
    _initializeListeners();
  }

  // Streams
  Stream<ChatMessage> get incomingMessages => _messageController.stream;
  Stream<List<ChatSession>> get activeSessions => _sessionController.stream;
  Stream<List<ExtensionRequest>> get extensionRequests =>
      _extensionRequestController.stream;

  // Initialize Firebase listeners
  void _initializeListeners() {
    _listenToIncomingMessages();
    _listenToExtensionRequests();
  }

  // Listen to incoming messages for this user
  void _listenToIncomingMessages() {
    _messageSubscription = _database
        .child('messages/$userId')
        .onChildAdded
        .listen((event) async {
          try {
            ChatMessage message = ChatMessage.fromJson(
              event.snapshot.key!,
              Map<String, dynamic>.from(event.snapshot.value as Map),
            );

            // Store message locally
            await _messageRepository.insertMessage(message);

            // Emit message to stream
            _messageController.add(message);

            // Auto-delete message from Firebase after receiving
            await _deleteFirebaseMessage(message.messageId);
          } catch (e) {
            print('Error processing incoming message: $e');
          }
        });
  }

  // Listen to extension requests
  void _listenToExtensionRequests() {
    getExtensionRequests().listen((requests) {
      _extensionRequestController.add(requests);
    });
  }

  // Send message (only if session is valid)
  Future<bool> sendMessage(
    String sessionId,
    String recipientId,
    String text,
  ) async {
    try {
      // Check if session is still valid in local database
      ChatSession? session = await _sessionRepository.getSession(sessionId);
      if (session != null && !session.isValid()) {
        return false;
      }

      // Check session validity in Firebase
      DataSnapshot sessionSnapshot = await _database
          .child('sessions/$sessionId')
          .get();

      if (!sessionSnapshot.exists) return false;

      ChatSession firebaseSession = ChatSession.fromJson(
        sessionId,
        Map<String, dynamic>.from(sessionSnapshot.value as Map),
      );

      if (!firebaseSession.isValid()) {
        await _expireSession(sessionId);
        return false;
      }

      // Generate message ID and create message
      String messageId = _database.child('messages/$recipientId').push().key!;

      ChatMessage message = ChatMessage(
        messageId: messageId,
        sender: userId,
        recipient: recipientId,
        text: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sessionId: sessionId,
      );

      // Send to Firebase
      await _database
          .child('messages/$recipientId/$messageId')
          .set(message.toJson());

      // Store locally as sent message
      await _messageRepository.insertMessage(message);

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Request session extension (requires consent from both users)
  Future<bool> requestSessionExtension(
    String sessionId,
    int additionalMinutes,
  ) async {
    try {
      DataSnapshot sessionSnapshot = await _database
          .child('sessions/$sessionId')
          .get();

      if (!sessionSnapshot.exists) return false;

      ChatSession session = ChatSession.fromJson(
        sessionId,
        Map<String, dynamic>.from(sessionSnapshot.value as Map),
      );

      if (!session.isParticipant(userId) || !session.isActive) return false;

      // Create extension request
      await _database.child('extension_requests/$sessionId').set({
        'requester': userId,
        'additional_minutes': additionalMinutes,
        'requested_at': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
        'expires_at': DateTime.now()
            .add(Duration(minutes: 5))
            .millisecondsSinceEpoch, // Request expires in 5 minutes
      });

      return true;
    } catch (e) {
      print('Error requesting session extension: $e');
      return false;
    }
  }

  // Respond to session extension request
  Future<bool> respondToExtensionRequest(String sessionId, bool approve) async {
    try {
      DataSnapshot sessionSnapshot = await _database
          .child('sessions/$sessionId')
          .get();

      if (!sessionSnapshot.exists) return false;

      ChatSession session = ChatSession.fromJson(
        sessionId,
        Map<String, dynamic>.from(sessionSnapshot.value as Map),
      );

      if (!session.isParticipant(userId) || !session.isActive) return false;

      DataSnapshot requestSnapshot = await _database
          .child('extension_requests/$sessionId')
          .get();

      if (!requestSnapshot.exists) return false;

      Map<String, dynamic> request = Map<String, dynamic>.from(
        requestSnapshot.value as Map,
      );

      // Check if request is still valid
      if (request['status'] != 'pending') return false;
      if (DateTime.now().millisecondsSinceEpoch >
          (request['expires_at'] as int)) {
        // Clean up expired request
        await _database.child('extension_requests/$sessionId').remove();
        return false;
      }

      // Check if the current user is not the requester
      if (request['requester'] == userId) return false;

      if (approve) {
        // Extend the session
        int additionalMinutes = request['additional_minutes'] as int;
        int newExpirationTime = DateTime.now()
            .add(Duration(minutes: additionalMinutes))
            .millisecondsSinceEpoch;

        await _database
            .child('sessions/$sessionId/expires_at')
            .set(newExpirationTime);

        // Update request status
        await _database
            .child('extension_requests/$sessionId/status')
            .set('approved');

        await _database
            .child('extension_requests/$sessionId/approved_at')
            .set(DateTime.now().millisecondsSinceEpoch);

        // Clean up request after short delay
        Future.delayed(Duration(seconds: 30), () {
          _database.child('extension_requests/$sessionId').remove();
        });
      } else {
        // Reject the request
        await _database
            .child('extension_requests/$sessionId/status')
            .set('rejected');

        await _database
            .child('extension_requests/$sessionId/rejected_at')
            .set(DateTime.now().millisecondsSinceEpoch);

        // Clean up request after short delay
        Future.delayed(Duration(seconds: 30), () {
          _database.child('extension_requests/$sessionId').remove();
        });
      }

      return true;
    } catch (e) {
      print('Error responding to extension request: $e');
      return false;
    }
  }

  // Listen to extension requests for sessions where this user is a participant
  Stream<List<ExtensionRequest>> getExtensionRequests() {
    return _database.child('extension_requests').onValue.asyncMap((
      event,
    ) async {
      List<ExtensionRequest> requests = [];

      if (event.snapshot.exists) {
        Map<String, dynamic> allRequests = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );

        for (var entry in allRequests.entries) {
          String sessionId = entry.key;
          Map<String, dynamic> requestData = entry.value;

          // Check if this user is a participant in the session
          DataSnapshot sessionSnapshot = await _database
              .child('sessions/$sessionId')
              .get();

          if (sessionSnapshot.exists) {
            ChatSession session = ChatSession.fromJson(
              sessionId,
              Map<String, dynamic>.from(sessionSnapshot.value as Map),
            );

            // Only include requests for sessions where this user is a participant
            // and they are not the requester
            if (session.isParticipant(userId) &&
                requestData['requester'] != userId) {
              ExtensionRequest request = ExtensionRequest.fromJson(
                sessionId,
                requestData,
              );
              if (request.isPending && !request.isExpired) {
                requests.add(request);
              }
            }
          }
        }
      }

      return requests;
    });
  }

  // Close session manually
  Future<void> closeSession(String sessionId) async {
    try {
      await _database.child('sessions/$sessionId/is_active').set(false);
    } catch (e) {
      print('Error closing session: $e');
    }
  }

  // Get local session data
  Future<ChatSession?> getSession(String sessionId) async {
    return await _sessionRepository.getSession(sessionId);
  }

  // Get local messages for a session
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    return await _messageRepository.getSessionMessages(sessionId);
  }

  // Get all local active sessions
  Future<List<ChatSession>> getLocalActiveSessions() async {
    return await _sessionRepository.getActiveSessions(userId);
  }

  // Set session nickname (local only)
  Future<bool> setSessionNickname(String sessionId, String nickname) async {
    try {
      await _sessionRepository.setSessionNickname(sessionId, nickname);
      return true;
    } catch (e) {
      print('Error setting session nickname: $e');
      return false;
    }
  }

  // Get session nickname
  Future<String?> getSessionNickname(String sessionId) async {
    return await _sessionRepository.getSessionNickname(sessionId);
  }

  // QR Session Management Methods

  // Create session with specific session ID and QR data
  Future<bool> createSession({
    required String sessionId,
    required String creatorId,
    required int createdAt,
    required int expiresAt,
  }) async {
    try {
      final Map<String, dynamic> sessionData = {
        'creator': creatorId,
        'joiner': userId, // Scanner automatically becomes joiner
        'created_at': createdAt,
        'expires_at': expiresAt,
        'is_active': false, // Initially inactive, waiting for confirmation
      };

      await _database.child('sessions/$sessionId').set(sessionData);

      return true;
    } catch (e) {
      print('Error creating session: $e');
      return false;
    }
  }

  // Activate session (called by generator to confirm)
  Future<bool> activateSession(String sessionId) async {
    try {
      await _database.child('sessions/$sessionId/is_active').set(true);
      return true;
    } catch (e) {
      print('Error activating session: $e');
      return false;
    }
  }

  // Listen to a specific session for changes (for QR generator)
  StreamSubscription<DatabaseEvent>? listenToSessionChanges(
    String sessionId,
    void Function(String? joinedUserId, bool isActive) onSessionChanged,
  ) {
    try {
      return _database.child('sessions/$sessionId').onValue.listen((
        event,
      ) async {
        if (event.snapshot.exists) {
          final sessionData = Map<String, dynamic>.from(
            event.snapshot.value as Map,
          );
          final creator = sessionData['creator'] as String?;
          final joiner = sessionData['joiner'] as String?;
          final isActive = sessionData['is_active'] as bool? ?? false;

          // If session was created but not active, and current user is the creator,
          // automatically activate it (generator confirms)
          if (!isActive && creator == userId && joiner?.isNotEmpty == true) {
            await activateSession(sessionId);
            return; // The listener will trigger again with is_active: true
          }

          onSessionChanged(
            joiner?.isNotEmpty == true ? joiner : null,
            isActive,
          );
        } else {
          onSessionChanged(null, false);
        }
      });
    } catch (e) {
      print('Error setting up session listener: $e');
      return null;
    }
  }

  // Private methods

  Future<void> _expireSession(String sessionId) async {
    try {
      await _database.child('sessions/$sessionId').remove();
      await _sessionRepository.deleteSession(sessionId);
    } catch (e) {
      print('Error expiring session: $e');
    }
  }

  Future<void> _deleteFirebaseMessage(String messageId) async {
    try {
      await _database.child('messages/$userId/$messageId').remove();
    } catch (e) {
      print('Error deleting Firebase message: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _messageSubscription?.cancel();
    _sessionSubscription?.cancel();
    _messageController.close();
    _sessionController.close();
    _extensionRequestController.close();
  }
}
