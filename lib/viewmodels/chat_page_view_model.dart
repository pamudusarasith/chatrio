import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class ChatPageViewModel extends ChangeNotifier {
  final String chatId;
  final UserService _userService = UserService();
  ChatService? _chatService;

  Chat? _chat;
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _currentUserId;
  final TextEditingController messageController = TextEditingController();

  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription? _chatStatusSubscription;

  Chat? get chat => _chat;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;

  ChatPageViewModel({required this.chatId}) {
    _initialize();
  }

  Future<void> _initialize() async {
    _setLoading(true);
    try {
      final user = await _userService.getCurrentUser();
      _currentUserId = user.id;

      // Use the singleton ChatService instance or create/initialize it
      _chatService = ChatService.instance;
      if (_chatService == null || _chatService!.userId != _currentUserId!) {
        _chatService = ChatService(userId: _currentUserId!);
        await _chatService!.initialize();
      }

      await _loadChat();
      await _loadMessages();
      _setupChatStatusListener();
      _setupMessageListener();
      _clearError();
    } catch (e) {
      _setError('Failed to load chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadChat() async {
    try {
      _chat = await _chatService?.getChat(chatId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load chat: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      _messages = await _chatService?.getChatMessages(chatId) ?? [];
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages: $e');
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _currentUserId == null || _chat == null) return;

    // Get the recipient
    final recipient = _chat!.getOtherParticipant(_currentUserId!);

    _setSending(true);

    // Clear the message input immediately for better UX
    messageController.clear();

    try {
      // Send message through chat service
      bool success = await _chatService!.sendMessage(chatId, recipient, text);

      if (success) {
        // Reload messages to show the sent message
        await _loadMessages();
        _clearError();
      } else {
        _setError('Failed to send message. Chat may have expired.');
        // Restore the text if sending failed
        messageController.text = text;
      }
    } catch (e) {
      _setError('Failed to send message: $e');
      // Restore the text if sending failed
      messageController.text = text;
    } finally {
      _setSending(false);
    }
  }

  Future<bool> deleteChat() async {
    try {
      if (_chatService == null) return false;
      final ok = await _chatService!.deleteLocalChat(chatId);
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changeNickname(String nickname) async {
    try {
      if (_chatService == null) return false;
      final ok = await _chatService!.setChatNickname(chatId, nickname);
      if (ok) {
        await _loadChat();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  void _setupMessageListener() {
    if (_chatService == null) return;

    _messageSubscription = _chatService!.incomingMessages.listen((message) {
      // Only add messages for this chat
      if (message.chatId == chatId) {
        _loadMessages(); // Reload messages when new message arrives
      }
    });
  }

  void _setupChatStatusListener() {
    if (_chatService == null) return;
    _chatStatusSubscription?.cancel();
    _chatStatusSubscription = _chatService!.listenToChatChanges(chatId, (
      joinedUserId,
      isActive,
    ) async {
      try {
        // Sync latest chat state from Firebase into local DB
        await _chatService!.syncChatFromFirebase(chatId);
        // Reload chat and reflect state changes (e.g., extension approval)
        await _loadChat();
      } catch (_) {
        // ignore transient errors
      }
    });
  }

  void _setSending(bool sending) {
    _isSending = sending;
    notifyListeners();
  }

  String getChatDisplayName() {
    if (_currentUserId == null || _chat == null) return 'Chat';
    return _chat!.getDisplayName(_currentUserId!);
  }

  String getFormattedDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    messageController.dispose();
    _messageSubscription?.cancel();
    _chatStatusSubscription?.cancel();
    // Don't dispose the singleton ChatService, just cancel our subscription
    super.dispose();
  }
}
