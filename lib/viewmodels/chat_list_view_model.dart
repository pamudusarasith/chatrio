import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import '../repositories/message_repository.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';

class ChatListViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();
  final MessageRepository _messageRepository = MessageRepository();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _currentUserId;
  String? _errorMessage;
  List<Chat> _activeChats = [];
  List<Chat> _expiredChats = [];
  Map<String, Message?> _lastMessages = {};

  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get errorMessage => _errorMessage;
  List<Chat> get activeChats => _activeChats;
  List<Chat> get expiredChats => _expiredChats;
  bool get hasChats => _activeChats.isNotEmpty || _expiredChats.isNotEmpty;
  Message? getLastMessage(String chatId) => _lastMessages[chatId];

  ChatListViewModel() {
    _initialize();
  }

  Future<void> _loadChatsAndMessages() async {
    if (_currentUserId == null) return;
    try {
      final allChats = await _chatRepository.getUserChats(_currentUserId!);
      _activeChats = [];
      _expiredChats = [];
      _lastMessages = {};
      for (final chat in allChats) {
        if (chat.isValid()) {
          _activeChats.add(chat);
        } else {
          _expiredChats.add(chat);
        }
        // Get last message for each chat
        final messages = await _messageRepository.getChatMessages(chat.chatId);
        _lastMessages[chat.chatId] = messages.isNotEmpty ? messages.last : null;
      }
      _activeChats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _expiredChats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      _setError('Failed to load chats/messages: $e');
    }
  }

  Future<void> _initialize() async {
    _setLoading(true);
    try {
      final currentUser = await _userService.getCurrentUser();
      _currentUserId = currentUser.id;
      await _loadChatsAndMessages();
      _clearError();
    } catch (e) {
      _setError('Failed to load chats: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshChats() async {
    await _loadChatsAndMessages();
  }

  Future<void> updateChatNickname(String chatId, String nickname) async {
    try {
      await _chatRepository.setChatNickname(chatId, nickname);

      // Update the local chat object
      _updateChatInList(chatId, (chat) => chat.copyWith(nickname: nickname));

      notifyListeners();
    } catch (e) {
      _setError('Failed to update nickname: $e');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      if (_currentUserId == null) throw Exception('No current user');

      // Prefer using ChatService to ensure messages are deleted safely
      var chatService = ChatService.instance;
      if (chatService == null || chatService.userId != _currentUserId!) {
        chatService = ChatService(userId: _currentUserId!);
        // No need to initialize for local delete
      }

      final ok = await chatService.deleteLocalChat(chatId);
      if (!ok) throw Exception('Local delete failed');

      // Remove from local lists
      _activeChats.removeWhere((chat) => chat.chatId == chatId);
      _expiredChats.removeWhere((chat) => chat.chatId == chatId);
      _lastMessages.remove(chatId);

      notifyListeners();
    } catch (e) {
      _setError('Failed to delete chat: $e');
    }
  }

  void _updateChatInList(String chatId, Chat Function(Chat) updateFunction) {
    // Update in active chats
    for (int i = 0; i < _activeChats.length; i++) {
      if (_activeChats[i].chatId == chatId) {
        _activeChats[i] = updateFunction(_activeChats[i]);
        return;
      }
    }

    // Update in expired chats
    for (int i = 0; i < _expiredChats.length; i++) {
      if (_expiredChats[i].chatId == chatId) {
        _expiredChats[i] = updateFunction(_expiredChats[i]);
        return;
      }
    }
  }

  String getChatDisplayName(Chat chat) {
    if (_currentUserId == null) return 'Unknown Chat';
    return chat.getDisplayName(_currentUserId!);
  }

  String getFormattedDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      // Older
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
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
}
