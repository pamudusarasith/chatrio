import 'package:chatrio/services/user_service.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

class HomeViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  // State variables
  bool _isLoading = false;
  String? _currentUserId;
  String? _errorMessage;
  bool _isUserInitialized = false;

  HomeViewModel() {
    _initializeUser();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get errorMessage => _errorMessage;
  bool get isUserInitialized => _isUserInitialized;

  Future<void> _initializeUser() async {
    _setLoading(true);
    try {
      // Get or create current user
      User currentUser = await _userService.getCurrentUser();
      _currentUserId = currentUser.id;

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
}
