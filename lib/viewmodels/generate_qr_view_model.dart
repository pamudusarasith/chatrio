import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/qr_service.dart';
import '../services/chat_service.dart';

class GenerateQRViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final Uuid _uuid = const Uuid();
  ChatService? _chatService;

  // State variables
  bool _isLoading = false;
  String? _currentUserId;
  String? _currentSessionId;
  String? _errorMessage;
  bool _isQRGenerated = false;
  bool _isSessionActive = false;
  String? _joinedUserId;

  // Stream subscription for session changes
  StreamSubscription? _sessionSubscription;

  GenerateQRViewModel() {
    _initializeUser();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get currentSessionId => _currentSessionId;
  String? get errorMessage => _errorMessage;
  bool get isQRGenerated => _isQRGenerated;
  bool get isSessionActive => _isSessionActive;
  String? get joinedUserId => _joinedUserId;

  String get qrCodeData {
    if (_currentUserId == null || _currentSessionId == null) {
      return '';
    }
    // Use QR service to generate properly formatted QR data
    return QRService.generateSessionQR(_currentSessionId!, _currentUserId!);
  }

  Future<void> _initializeUser() async {
    _setLoading(true);
    try {
      User currentUser = await _userService.getCurrentUser();
      _currentUserId = currentUser.id;

      // Initialize chat service
      _chatService = ChatService(userId: _currentUserId!);

      // Always generate a new session ID on initialization
      _generateNewSessionId();
      _isQRGenerated = true;
      _clearError();
    } catch (e) {
      _setError('User initialization failed. Restart the app.');
    } finally {
      _setLoading(false);
    }
  }

  void _generateNewSessionId() {
    if (_currentUserId == null) {
      _setError('User initialization failed. Restart the app.');
      return;
    }

    // Stop listening to previous session if any
    _stopSessionListening();

    // Reset session state
    _isSessionActive = false;
    _joinedUserId = null;

    _currentSessionId = _uuid.v4();

    // Start listening for when someone joins this session
    _startSessionListening();

    notifyListeners();
  }

  Future<void> generateNewQRCode() async {
    _setLoading(true);
    try {
      // Only regenerate session ID, keep user ID persistent
      _generateNewSessionId();
    } catch (e) {
      _setError('Failed to generate new QR code: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> regenerateSessionId() async {
    _setLoading(true);
    try {
      _generateNewSessionId();
      _clearError();
    } catch (e) {
      _setError('Failed to regenerate session ID: $e');
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

  // Session listening methods
  void _startSessionListening() {
    if (_currentSessionId == null || _chatService == null) return;

    _sessionSubscription = _chatService!.listenToSessionChanges(
      _currentSessionId!,
      (joinedUserId, isActive) {
        if (joinedUserId != null && joinedUserId.isNotEmpty) {
          // Someone joined the session!
          _isSessionActive = true;
          _joinedUserId = joinedUserId;
          print('User $joinedUserId joined session $_currentSessionId');
          notifyListeners();
        }
      },
    );
  }

  void _stopSessionListening() {
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
  }

  @override
  void dispose() {
    _stopSessionListening();
    super.dispose();
  }
}
