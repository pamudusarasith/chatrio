import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/qr_service.dart';
import '../services/chat_service.dart';
import '../utils/logger.dart';

class GenerateQRViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final Uuid _uuid = const Uuid();
  ChatService? _chatService;

  // State variables
  bool _isLoading = false;
  String? _currentUserId;
  String? _currentChatId;
  String? _errorMessage;
  bool _isQRGenerated = false;
  bool _isChatActive = false;
  String? _joinedUserId;

  // Stream subscription for chat changes
  StreamSubscription? _chatSubscription;

  GenerateQRViewModel() {
    _initializeUser();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get currentChatId => _currentChatId;
  String? get errorMessage => _errorMessage;
  bool get isQRGenerated => _isQRGenerated;
  bool get isChatActive => _isChatActive;
  String? get joinedUserId => _joinedUserId;

  String get qrCodeData {
    if (_currentUserId == null || _currentChatId == null) {
      return '';
    }
    // Use QR service to generate properly formatted QR data
    return QRService.generateChatQR(_currentChatId!, _currentUserId!);
  }

  Future<void> _initializeUser() async {
    _setLoading(true);
    try {
      User currentUser = await _userService.getCurrentUser();
      _currentUserId = currentUser.id;

      // Initialize chat service
      _chatService = ChatService(userId: _currentUserId!);

      // Always generate a new chat ID on initialization
      _generateNewChatId();
      _isQRGenerated = true;
      _clearError();
    } catch (e) {
      _setError('User initialization failed. Restart the app.');
    } finally {
      _setLoading(false);
    }
  }

  void _generateNewChatId() {
    if (_currentUserId == null) {
      _setError('User initialization failed. Restart the app.');
      return;
    }

    // Stop listening to previous chat if any
    _stopChatListening();

    // Reset chat state
    _isChatActive = false;
    _joinedUserId = null;

    _currentChatId = _uuid.v4();

    // Start listening for when someone joins this chat
    _startChatListening();

    notifyListeners();
  }

  Future<void> generateNewQRCode() async {
    _setLoading(true);
    try {
      // Only regenerate chat ID, keep user ID persistent
      _generateNewChatId();
    } catch (e) {
      _setError('Failed to generate new QR code: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> regenerateChatId() async {
    _setLoading(true);
    try {
      _generateNewChatId();
      _clearError();
    } catch (e) {
      _setError('Failed to regenerate chat ID: $e');
    } finally {
      _setLoading(false);
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

  // Public method for UI to clear errors
  void clearError() => _clearError();

  // Chat listening methods
  void _startChatListening() {
    if (_currentChatId == null || _chatService == null) return;

    _chatSubscription = _chatService!.listenToChatChanges(_currentChatId!, (
      joinedUserId,
      isActive,
    ) {
      if (joinedUserId != null && joinedUserId.isNotEmpty) {
        // Someone joined the chat!
        _isChatActive = true;
        _joinedUserId = joinedUserId;
        AppLogger.info('User $joinedUserId joined chat $_currentChatId');
        notifyListeners();
      }
    });
  }

  void _stopChatListening() {
    _chatSubscription?.cancel();
    _chatSubscription = null;
  }

  // Handle start chatting action
  Future<bool> startChatting(String nickname) async {
    if (_currentChatId == null || _chatService == null) {
      _setError('No active chat to save');
      return false;
    }

    try {
      _setLoading(true);

      // Save chat locally with nickname
      bool success = await _chatService!.saveChatLocally(
        _currentChatId!,
        nickname,
      );

      if (success) {
        AppLogger.info(
          'Chat saved locally for generator with nickname: $nickname',
        );
        _clearError();
        return true;
      } else {
        _setError('Failed to save chat locally');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error starting chat for generator', e);
      _setError('Error starting chat: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _stopChatListening();
    super.dispose();
  }
}
