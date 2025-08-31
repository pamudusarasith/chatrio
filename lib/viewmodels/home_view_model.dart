import 'package:chatrio/services/user_service.dart';
import 'package:chatrio/services/chat_service.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

class HomeViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  ChatService? _chatService;

  // State variables
  bool _isLoading = false;
  String? _currentUserId;
  String? _errorMessage;
  bool _isUserInitialized = false;

  HomeViewModel() {
    _bootstrap();
  }

  void _bootstrap() {
    // If SplashPage already initialized ChatService, adopt it immediately
    final existing = ChatService.instance;
    if (existing != null) {
      _chatService = existing;
      _currentUserId = existing.userId;
      _isUserInitialized = true;
      _clearError();
      notifyListeners();
    } else {
      // Fallback: initialize when Splash wasn't used (e.g., deep link)
      _initializeUser();
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get errorMessage => _errorMessage;
  bool get isUserInitialized => _isUserInitialized;
  ChatService? get chatService => _chatService;

  Future<void> _initializeUser() async {
    _setLoading(true);
    try {
      // Get or create current user
      User currentUser = await _userService.getCurrentUser();
      _currentUserId = currentUser.id;

      // Initialize ChatService and retrieve pending messages
      _chatService = ChatService(userId: _currentUserId!);
      await _chatService!.initialize();

      _isUserInitialized = true;
      _clearError();
    } catch (e) {
      _setError('Failed to initialize user: $e');
      _isUserInitialized = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initializeUser() async {
    await _initializeUser();
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
    _chatService?.dispose();
    super.dispose();
  }
}
