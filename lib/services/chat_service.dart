import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/extension_request.dart';
import '../repositories/chat_repository.dart';
import '../repositories/message_repository.dart';
import '../utils/logger.dart';

class ChatService {
  static ChatService? _instance;

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

  bool _isInitialized = false;

  ChatService._internal({required this.userId});

  // Singleton factory constructor
  factory ChatService({required String userId}) {
    if (_instance == null || _instance!.userId != userId) {
      _instance?.dispose(); // Dispose previous instance if exists
      _instance = ChatService._internal(userId: userId);
    }
    return _instance!;
  }

  // Get existing instance (returns null if not initialized)
  static ChatService? get instance => _instance;

  // Public initialization method
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _initialize();
      _isInitialized = true;
    }
  }

  // Streams
  Stream<Message> get incomingMessages => _messageController.stream;
  Stream<List<Chat>> get activeChats => _chatController.stream;
  Stream<List<ExtensionRequest>> get extensionRequests =>
      _extensionRequestController.stream;

  // Initialize Firebase listeners
  Future<void> _initialize() async {
    // First, retrieve all pending messages and clear the queue (with timeout)
    try {
      await _retrieveAllPendingMessages().timeout(const Duration(seconds: 6));
    } on TimeoutException {
      AppLogger.warning(
        'Pending messages retrieval timed out; starting listeners anyway',
      );
    } catch (e, st) {
      AppLogger.error('Error retrieving pending messages', e, st);
    }

    // Then start listening for new messages
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
            final key = event.snapshot.key;
            final raw = event.snapshot.value;
            if (key == null || raw == null || raw is! Map) {
              return; // Ignore malformed entries
            }
            Message message = Message.fromJson(
              key,
              Map<String, dynamic>.from(raw),
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

  // Retrieve all pending messages and clear the Firebase queue
  Future<void> _retrieveAllPendingMessages() async {
    try {
      AppLogger.info('Retrieving all pending messages for user: $userId');

      DataSnapshot snapshot = await _database.child('messages/$userId').get();

      if (snapshot.exists) {
        final raw = snapshot.value;
        if (raw == null || raw is! Map) {
          AppLogger.warning('Pending messages payload malformed; skipping');
          return;
        }
        Map<String, dynamic> messagesData = Map<String, dynamic>.from(raw);

        List<Message> messages = [];

        // Process each message
        for (var entry in messagesData.entries) {
          try {
            String messageId = entry.key;
            if (entry.value is! Map) {
              continue; // Skip invalid message entry
            }
            Map<String, dynamic> messageData = Map<String, dynamic>.from(
              entry.value,
            );

            Message message = Message.fromJson(messageId, messageData);
            messages.add(message);

            // Store message locally
            await _messageRepository.insertMessage(message);

            AppLogger.info(
              'Retrieved message: ${message.messageId} from ${message.sender}',
            );
          } catch (e) {
            AppLogger.error('Error processing message ${entry.key}', e);
          }
        }

        // Clear all messages from Firebase after successful retrieval
        await _database.child('messages/$userId').remove();

        // Emit all messages to the stream
        for (Message message in messages) {
          _messageController.add(message);
        }

        AppLogger.info(
          'Successfully retrieved and cleared ${messages.length} pending messages',
        );
      } else {
        AppLogger.info('No pending messages found for user: $userId');
      }
    } catch (e) {
      AppLogger.error('Error retrieving pending messages', e);
    }
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

      // Allow requesting extension if participant, regardless of active flag.
      if (!chat.isParticipant(userId)) return false;

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

      // Allow responding if participant, regardless of active flag.
      if (!chat.isParticipant(userId)) return false;

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

        // Ensure chat is marked active again upon extension approval
        await _database.child('chats/$chatId/is_active').set(true);

        // Update request status
        await _database
            .child('extension_requests/$chatId/status')
            .set('approved');

        await _database
            .child('extension_requests/$chatId/approved_at')
            .set(DateTime.now().millisecondsSinceEpoch);

        // Sync local chat with updated state
        await syncChatFromFirebase(chatId);

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

        // Sync local chat (no change to chat in this branch but keep parity)
        await syncChatFromFirebase(chatId);

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

  // Delete a chat locally (and its messages)
  Future<bool> deleteLocalChat(String chatId) async {
    try {
      // Delete messages first for safety (SQLite FKs may not be enforced)
      await _messageRepository.deleteChatMessages(chatId);
      await _chatRepository.deleteChat(chatId);
      return true;
    } catch (e) {
      AppLogger.error('Error deleting local chat', e);
      return false;
    }
  }

  // Sync a chat from Firebase into local database
  Future<bool> syncChatFromFirebase(String chatId) async {
    try {
      final snap = await _database.child('chats/$chatId').get();
      if (!snap.exists) return false;
      final chat = Chat.fromJson(
        chatId,
        Map<String, dynamic>.from(snap.value as Map),
      );
      if (!chat.isParticipant(userId)) return false;

      final existing = await _chatRepository.getChat(chatId);
      if (existing == null) {
        await _chatRepository.insertChat(chat);
      } else {
        await _chatRepository.updateChat(chat);
        await _chatRepository.setChatNickname(chatId, existing.nickname!);
      }
      return true;
    } catch (e) {
      AppLogger.error('Error syncing chat from Firebase', e);
      return false;
    }
  }

  // Save chat locally with nickname
  Future<bool> saveChatLocally(String chatId, String nickname) async {
    try {
      // Get the chat data from Firebase
      DataSnapshot chatSnapshot = await _database.child('chats/$chatId').get();

      if (!chatSnapshot.exists) {
        AppLogger.error(
          'Chat not found in Firebase when trying to save locally',
        );
        return false;
      }

      Chat chat = Chat.fromJson(
        chatId,
        Map<String, dynamic>.from(chatSnapshot.value as Map),
      );

      // Check if user is a participant
      if (!chat.isParticipant(userId)) {
        AppLogger.error('User is not a participant in this chat');
        return false;
      }

      // Save chat locally
      await _chatRepository.insertChat(chat);

      // Set nickname if provided
      if (nickname.isNotEmpty) {
        await _chatRepository.setChatNickname(chatId, nickname);
      }

      AppLogger.info('Chat saved locally with nickname: $nickname');
      return true;
    } catch (e) {
      AppLogger.error('Error saving chat locally', e);
      return false;
    }
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
      // Do not delete chat anymore. We keep it and block messaging via validity checks.
      // Optionally, ensure is_active is false in Firebase so both clients see it's inactive.
      await _database.child('chats/$chatId/is_active').set(false);
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
