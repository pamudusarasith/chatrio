import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class GenerateQRViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final Uuid _uuid = const Uuid();

  // State variables
  bool _isLoading = false;
  String? _currentUserId;
  String? _errorMessage;
  bool _isQRGenerated = false;

  GenerateQRViewModel(UserRepository userRepository)
    : _userRepository = userRepository {
    _initializeUser();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get errorMessage => _errorMessage;
  bool get isQRGenerated => _isQRGenerated;

  Future<void> _initializeUser() async {
    _setLoading(true);
    try {
      // Check if user already exists
      User? existingUser = await _userRepository.getCurrentUser();

      if (existingUser != null) {
        _currentUserId = existingUser.id;
        _isQRGenerated = true;
      } else {
        await _generateNewUser();
      }
    } catch (e) {
      _setError('Failed to initialize user: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _generateNewUser() async {
    try {
      _currentUserId = _uuid.v4();
      final user = User(id: _currentUserId!, createdAt: DateTime.now());
      await _userRepository.saveUser(user);
      _isQRGenerated = true;
      _clearError();
    } catch (e) {
      _setError('Failed to generate user ID: $e');
    }
  }

  Future<void> generateNewQRCode() async {
    _setLoading(true);
    try {
      // Clear existing user and generate new one
      if (_currentUserId != null) {
        await _userRepository.deleteUser(_currentUserId!);
      }
      await _generateNewUser();
    } catch (e) {
      _setError('Failed to generate new QR code: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> copyToClipboard() async {
    if (_currentUserId != null) {
      try {
        await Clipboard.setData(ClipboardData(text: _currentUserId!));
      } catch (e) {
        _setError('Failed to copy to clipboard: $e');
      }
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
