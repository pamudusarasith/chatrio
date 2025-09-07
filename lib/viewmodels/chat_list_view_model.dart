import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chat.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import '../repositories/message_repository.dart';
import '../models/extension_request.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';

class ChatListViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();
  final MessageRepository _messageRepository = MessageRepository();
  final UserService _userService = UserService();
  ChatService? _chatService;

  bool _isLoading = false;
  String? _currentUserId;
  String? _errorMessage;
  List<Chat> _activeChats = [];
  List<Chat> _expiredChats = [];
  Map<String, Message?> _lastMessages = {};
  List<ExtensionRequest> _incomingRequests = [];
  List<ExtensionRequest> _myPendingRequests = [];
  Set<String> _myPendingIds = {};
  StreamSubscription? _extensionSubscription;
  StreamSubscription? _myExtensionSubscription;

  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get errorMessage => _errorMessage;
  List<Chat> get activeChats => _activeChats;
  List<Chat> get expiredChats => _expiredChats;
  bool get hasChats => _activeChats.isNotEmpty || _expiredChats.isNotEmpty;
  Message? getLastMessage(String chatId) => _lastMessages[chatId];
  List<ExtensionRequest> get incomingRequests => _incomingRequests;
  List<ExtensionRequest> get myPendingRequests => _myPendingRequests;

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
      // Ensure ChatService available for extension requests
      _chatService = ChatService.instance;
      if (_chatService == null || _chatService!.userId != _currentUserId!) {
        _chatService = ChatService(userId: _currentUserId!);
        // No need to await initialize for local operations; but safe to initialize once
        await _chatService!.initialize();
      }
      await _loadChatsAndMessages();
      _setupExtensionListener();
      _setupMyExtensionListener();
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

  void _setupExtensionListener() {
    if (_chatService == null) return;
    _extensionSubscription?.cancel();
    _extensionSubscription = _chatService!.getExtensionRequests().listen((
      list,
    ) async {
      // Convert maps to ExtensionRequest models
      final requests = <ExtensionRequest>[];
      for (final item in list) {
        final chatId = item['chatId'] as String;
        final map = Map<String, dynamic>.from(item);
        map.remove('chatId');
        final req = ExtensionRequest.fromJson(chatId, map);
        if (req.isPending && !req.isExpired) {
          requests.add(req);
        }
      }
      _incomingRequests = requests;
      notifyListeners();
    }, onError: (_) {});
  }

  void _setupMyExtensionListener() {
    if (_chatService == null) return;
    _myExtensionSubscription?.cancel();
    _myExtensionSubscription = _chatService!.getMyExtensionRequests().listen((
      list,
    ) async {
      final requests = <ExtensionRequest>[];
      for (final item in list) {
        final chatId = item['chatId'] as String;
        final map = Map<String, dynamic>.from(item);
        map.remove('chatId');
        final req = ExtensionRequest.fromJson(chatId, map);
        if (req.isPending && !req.isExpired) {
          requests.add(req);
        }
      }
      final newIds = requests.map((r) => r.chatId).toSet();
      // Detect which requests were removed (approved or rejected by the other user)
      final removed = _myPendingIds.difference(newIds);
      final changed =
          newIds.length != _myPendingIds.length ||
          !_myPendingIds.containsAll(newIds) ||
          !newIds.containsAll(_myPendingIds);
      _myPendingRequests = requests;
      _myPendingIds = newIds;
      notifyListeners();
      // If a pending request was approved/rejected, refresh chats to reflect state
      if (changed) {
        // Pull latest chat state from Firebase for affected chats first
        if (_chatService != null) {
          for (final id in removed) {
            try {
              await _chatService!.syncChatFromFirebase(id);
            } catch (_) {}
          }
        }
        await _loadChatsAndMessages();
      }
    }, onError: (_) {});
  }

  Future<bool> approveExtension(String chatId) async {
    if (_chatService == null) return false;
    try {
      final ok = await _chatService!.respondToExtensionRequest(chatId, true);
      if (ok) {
        await _loadChatsAndMessages();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectExtension(String chatId) async {
    if (_chatService == null) return false;
    try {
      final ok = await _chatService!.respondToExtensionRequest(chatId, false);
      if (ok) {
        // No change to chat data; still refresh extension list
        await _loadChatsAndMessages();
      }
      return ok;
    } catch (_) {
      return false;
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

  @override
  void dispose() {
    _extensionSubscription?.cancel();
    _myExtensionSubscription?.cancel();
    super.dispose();
  }
}
