import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/extension_request.dart';
import '../repositories/chat_repository.dart';
import '../repositories/message_repository.dart';
import '../utils/logger.dart';

class ChatService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final ChatRepository _chatRepository = ChatRepository();
  final MessageRepository _messageRepository = MessageRepository();
  final String userId;

  StreamSubscription<DatabaseEvent>? _messageSubscription;
  StreamSubscription<DatabaseEvent>? _chatSubscription;

  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<List<Chat>> _chatController =
      StreamController<List<Chat>>.broadcast();
  final StreamController<List<ExtensionRequest>> _extensionRequestController =
      StreamController<List<ExtensionRequest>>.broadcast();

  ChatService({required this.userId}) {
    _initializeListeners();
  }

  // Streams
  Stream<Message> get incomingMessages => _messageController.stream;
  Stream<List<Chat>> get activeChats => _chatController.stream;
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
            Message message = Message.fromJson(
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
            AppLogger.error('Error processing incoming message', e);
          }
        });
  }

  // Listen to extension requests
  void _listenToExtensionRequests() {
    getExtensionRequests().listen((requests) {
      _extensionRequestController.add(requests);
    });
  }

  // Send message (only if chat is valid)
  Future<bool> sendMessage(
    String chatId,
    String recipientId,
    String text,
  ) async {
    try {
      // Check if chat is still valid in local database
      Chat? chat = await _chatRepository.getChat(chatId);
      if (chat != null && !chat.isValid()) {
        return false;
      }

      // Check chat validity in Firebase
      DataSnapshot chatSnapshot = await _database.child('chats/$chatId').get();

      if (!chatSnapshot.exists) return false;

      Chat firebaseChat = Chat.fromJson(
        chatId,
        Map<String, dynamic>.from(chatSnapshot.value as Map),
      );

      if (!firebaseChat.isValid()) {
        await _expireChat(chatId);
        return false;
      }

      // Generate message ID and create message
      String messageId = _database.child('messages/$recipientId').push().key!;

      Message message = Message(
        messageId: messageId,
        sender: userId,
        recipient: recipientId,
        text: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        chatId: chatId,
      );

      // Send to Firebase
      await _database
          .child('messages/$recipientId/$messageId')
          .set(message.toJson());

      // Store locally as sent message
      await _messageRepository.insertMessage(message);

      return true;
    } catch (e) {
      AppLogger.error('Error sending message', e);
      return false;
    }
  }

  // Request chat extension (requires consent from both users)
  Future<bool> requestChatExtension(
    String chatId,
    int additionalMinutes,
  ) async {
    try {
      DataSnapshot chatSnapshot = await _database.child('chats/$chatId').get();

      if (!chatSnapshot.exists) return false;

      Chat chat = Chat.fromJson(
        chatId,
        Map<String, dynamic>.from(chatSnapshot.value as Map),
      );

      if (!chat.isParticipant(userId) || !chat.isActive) return false;

      // Create extension request
      await _database.child('extension_requests/$chatId').set({
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
      AppLogger.error('Error requesting chat extension', e);
      return false;
    }
  }

  // Respond to chat extension request
  Future<bool> respondToExtensionRequest(String chatId, bool approve) async {
    try {
      DataSnapshot chatSnapshot = await _database.child('chats/$chatId').get();

      if (!chatSnapshot.exists) return false;

      Chat chat = Chat.fromJson(
        chatId,
        Map<String, dynamic>.from(chatSnapshot.value as Map),
      );

      if (!chat.isParticipant(userId) || !chat.isActive) return false;

      DataSnapshot requestSnapshot = await _database
          .child('extension_requests/$chatId')
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
        await _database.child('extension_requests/$chatId').remove();
        return false;
      }

      // Check if the current user is not the requester
      if (request['requester'] == userId) return false;

      if (approve) {
        // Extend the chat
        int additionalMinutes = request['additional_minutes'] as int;
        int newExpirationTime = DateTime.now()
            .add(Duration(minutes: additionalMinutes))
            .millisecondsSinceEpoch;

        await _database
            .child('chats/$chatId/expires_at')
            .set(newExpirationTime);

        // Update request status
        await _database
            .child('extension_requests/$chatId/status')
            .set('approved');

        await _database
            .child('extension_requests/$chatId/approved_at')
            .set(DateTime.now().millisecondsSinceEpoch);

        // Clean up request after short delay
        Future.delayed(Duration(seconds: 30), () {
          _database.child('extension_requests/$chatId').remove();
        });
      } else {
        // Reject the request
        await _database
            .child('extension_requests/$chatId/status')
            .set('rejected');

        await _database
            .child('extension_requests/$chatId/rejected_at')
            .set(DateTime.now().millisecondsSinceEpoch);

        // Clean up request after short delay
        Future.delayed(Duration(seconds: 30), () {
          _database.child('extension_requests/$chatId').remove();
        });
      }

      return true;
    } catch (e) {
      AppLogger.error('Error responding to extension request', e);
      return false;
    }
  }

  // Listen to extension requests for chats where this user is a participant
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
          String chatId = entry.key;
          Map<String, dynamic> requestData = entry.value;

          // Check if this user is a participant in the chat
          DataSnapshot chatSnapshot = await _database
              .child('chats/$chatId')
              .get();

          if (chatSnapshot.exists) {
            Chat chat = Chat.fromJson(
              chatId,
              Map<String, dynamic>.from(chatSnapshot.value as Map),
            );

            // Only include requests for chats where this user is a participant
            // and they are not the requester
            if (chat.isParticipant(userId) &&
                requestData['requester'] != userId) {
              ExtensionRequest request = ExtensionRequest.fromJson(
                chatId,
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

  // Close chat manually
  Future<void> closeChat(String chatId) async {
    try {
      await _database.child('chats/$chatId/is_active').set(false);
    } catch (e) {
      AppLogger.error('Error closing chat', e);
    }
  }

  // Get local chat data
  Future<Chat?> getChat(String chatId) async {
    return await _chatRepository.getChat(chatId);
  }

  // Get local messages for a chat
  Future<List<Message>> getChatMessages(String chatId) async {
    return await _messageRepository.getChatMessages(chatId);
  }

  // Get all local active chats
  Future<List<Chat>> getLocalActiveChats() async {
    return await _chatRepository.getActiveChats(userId);
  }

  // Set chat nickname (local only)
  Future<bool> setChatNickname(String chatId, String nickname) async {
    try {
      await _chatRepository.setChatNickname(chatId, nickname);
      return true;
    } catch (e) {
      AppLogger.error('Error setting chat nickname', e);
      return false;
    }
  }

  // Get chat nickname
  Future<String?> getChatNickname(String chatId) async {
    return await _chatRepository.getChatNickname(chatId);
  }

  // QR Chat Management Methods

  // Create chat with specific chat ID and QR data
  Future<bool> createChat({
    required String chatId,
    required String creatorId,
    required int createdAt,
    required int expiresAt,
  }) async {
    try {
      final Map<String, dynamic> chatData = {
        'creator': creatorId,
        'joiner': userId, // Scanner automatically becomes joiner
        'created_at': createdAt,
        'expires_at': expiresAt,
        'is_active': false, // Initially inactive, waiting for confirmation
      };

      await _database.child('chats/$chatId').set(chatData);

      return true;
    } catch (e) {
      AppLogger.error('Error creating chat', e);
      return false;
    }
  }

  // Activate chat (called by generator to confirm)
  Future<bool> activateChat(String chatId) async {
    try {
      await _database.child('chats/$chatId/is_active').set(true);
      return true;
    } catch (e) {
      AppLogger.error('Error activating chat', e);
      return false;
    }
  }

  // Listen to a specific chat for changes (for QR generator)
  StreamSubscription<DatabaseEvent>? listenToChatChanges(
    String chatId,
    void Function(String? joinedUserId, bool isActive) onChatChanged,
  ) {
    try {
      return _database.child('chats/$chatId').onValue.listen((event) async {
        if (event.snapshot.exists) {
          final chatData = Map<String, dynamic>.from(
            event.snapshot.value as Map,
          );
          final creator = chatData['creator'] as String?;
          final joiner = chatData['joiner'] as String?;
          final isActive = chatData['is_active'] as bool? ?? false;

          // If chat was created but not active, and current user is the creator,
          // automatically activate it (generator confirms)
          if (!isActive && creator == userId && joiner?.isNotEmpty == true) {
            await activateChat(chatId);
            return; // The listener will trigger again with is_active: true
          }

          onChatChanged(joiner?.isNotEmpty == true ? joiner : null, isActive);
        } else {
          onChatChanged(null, false);
        }
      });
    } catch (e) {
      AppLogger.error('Error setting up chat listener', e);
      return null;
    }
  }

  // Private methods

  Future<void> _expireChat(String chatId) async {
    try {
      await _database.child('chats/$chatId').remove();
      await _chatRepository.deleteChat(chatId);
    } catch (e) {
      AppLogger.error('Error expiring chat', e);
    }
  }

  Future<void> _deleteFirebaseMessage(String messageId) async {
    try {
      await _database.child('messages/$userId/$messageId').remove();
    } catch (e) {
      AppLogger.error('Error deleting Firebase message', e);
    }
  }

  // Dispose resources
  void dispose() {
    _messageSubscription?.cancel();
    _chatSubscription?.cancel();
    _messageController.close();
    _chatController.close();
    _extensionRequestController.close();
  }
}
