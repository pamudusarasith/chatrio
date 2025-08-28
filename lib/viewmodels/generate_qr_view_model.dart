import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class GenerateQRViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final Uuid _uuid = const Uuid();

  // State variables
  bool _isLoading = false;
  String? _currentUserId;
  String? _currentSessionId;
  String? _errorMessage;
  bool _isQRGenerated = false;

  GenerateQRViewModel(UserRepository userRepository)
    : _userRepository = userRepository {
    _initializeUser();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get currentSessionId => _currentSessionId;
  String? get errorMessage => _errorMessage;
  bool get isQRGenerated => _isQRGenerated;

  String get qrCodeData {
    if (_currentUserId == null || _currentSessionId == null) {
      return '';
    }
    return jsonEncode({
      'userId': _currentUserId,
      'sessionId': _currentSessionId,
    });
  }

  Future<void> _initializeUser() async {
    _setLoading(true);
    try {
      // Check if user already exists
      User? existingUser = await _userRepository.getCurrentUser();

      if (existingUser != null) {
        _currentUserId = existingUser.id;
      } else {
        // Generate new persistent user ID
        _currentUserId = _uuid.v4();
        final user = User(id: _currentUserId!, createdAt: DateTime.now());
        await _userRepository.saveUser(user);
      }

      // Always generate a new session ID on initialization
      _generateNewSessionId();
      _isQRGenerated = true;
      _clearError();
    } catch (e) {
      _setError('Failed to initialize user: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _generateNewSessionId() {
    _currentSessionId = _uuid.v4();
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
