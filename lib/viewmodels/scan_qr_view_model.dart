import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/qr_service.dart';
import '../utils/logger.dart';

class ScanQRViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  late MobileScannerController _scannerController;
  late ChatService _chatService;
  StreamSubscription? _chatSubscription;

  // State variables
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isWaitingForActivation = false;
  String? _currentUserId;
  String? _errorMessage;
  Map<String, dynamic>? _parsedQRData;
  String? _chatId;
  bool _isValidQR = false;

  ScanQRViewModel() {
    _initializeUser();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isWaitingForActivation => _isWaitingForActivation;
  String? get currentUserId => _currentUserId;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get parsedQRData => _parsedQRData;
  String? get chatId => _chatId;
  bool get isValidQR => _isValidQR;
  String? get creatorId => _parsedQRData?['creator_id'];
  MobileScannerController get scannerController => _scannerController;

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );
  }

  Future<void> _initializeUser() async {
    _setLoading(true);
    try {
      User currentUser = await _userService.getCurrentUser();
      _currentUserId = currentUser.id;

      // Initialize scanner only after user is successfully initialized
      _initializeScanner();

      // Initialize chat service
      _chatService = ChatService(userId: _currentUserId!);

      _clearError();
    } catch (e) {
      _setError('User initialization failed. Restart the app.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initializeUser() async {
    await _initializeUser();
  }

  void onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        _handleScannedData(barcode.rawValue!);
      }
    }
  }

  void _handleScannedData(String data) {
    // Log scanned QR code data
    AppLogger.debug('QR Code Scanned: $data');

    // Reset validation state
    _isValidQR = false;
    _chatId = null;
    _parsedQRData = null;

    // Check if it's a Chatrio QR code using QR service
    if (QRService.isChatrioQR(data)) {
      // Parse QR data using QR service
      _parsedQRData = QRService.parseQRData(data);

      if (_parsedQRData != null) {
        AppLogger.debug('Parsed QR Data: $_parsedQRData');

        // Validate the QR data using QR service
        if (QRService.isValidChatQR(_parsedQRData!)) {
          _isValidQR = true;
          _chatId = QRService.getChatIdFromQR(data);

          AppLogger.info('Valid Chatrio QR detected!');
          AppLogger.debug('Chat ID: $_chatId');
          AppLogger.debug('Creator ID: ${_parsedQRData!['creator_id']}');
          AppLogger.debug('Timestamp: ${_parsedQRData!['timestamp']}');

          if (_parsedQRData!['expires_at'] != null) {
            AppLogger.debug('Expires at: ${_parsedQRData!['expires_at']}');
          }

          _clearError();

          // Automatically create the chat
          _createChat();
        } else {
          AppLogger.warning('Invalid or expired Chatrio QR code');
          _setError('Invalid or expired QR code');
        }
      } else {
        AppLogger.warning('Failed to parse Chatrio QR code');
        _setError('Invalid QR code format');
      }
    } else {
      AppLogger.info('Not a Chatrio QR code: $data');
      _setError('This is not a valid Chatrio QR code');
    }

    notifyListeners();
  }

  // Create chat (called automatically when valid QR is scanned)
  Future<void> _createChat() async {
    if (!_isValidQR || _chatId == null || _parsedQRData == null) {
      return;
    }

    _isCreating = true;
    _setLoading(true);

    try {
      AppLogger.info('Automatically creating chat...');

      // Use chat service to create the chat
      bool success = await _chatService.createChat(
        chatId: _chatId!,
        creatorId: _parsedQRData!['creator_id'],
        createdAt: _parsedQRData!['created_at'],
        expiresAt: _parsedQRData!['expires_at'],
      );

      if (success) {
        AppLogger.info('Successfully created chat: $_chatId');
        _clearError();

        // Now wait for the chat to be activated by the generator
        _waitForChatActivation();
      } else {
        AppLogger.error('Failed to create chat');
        _setError('Failed to create chat.');
      }
    } catch (e) {
      AppLogger.error('Error joining chat', e);
      _setError('Error joining chat: $e');
    } finally {
      _isCreating = false;
      _setLoading(false);
    }
  }

  // Wait for the chat to be activated by the generator
  void _waitForChatActivation() {
    if (_chatId == null) return;

    _isWaitingForActivation = true;
    _isCreating = false;
    notifyListeners();

    AppLogger.info('Waiting for generator to activate chat...');

    _chatSubscription = _chatService.listenToChatChanges(_chatId!, (
      joinedUserId,
      isActive,
    ) {
      if (isActive) {
        AppLogger.info('Chat activated! Both users confirmed.');
        _isWaitingForActivation = false;
        _setLoading(false);
        _clearError();

        // Chat is now active and saved locally by ChatService
        _stopListening();
      }
    });
  }

  // Stop listening to chat changes
  void _stopListening() {
    _chatSubscription?.cancel();
    _chatSubscription = null;
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

  @override
  void dispose() {
    _stopListening();
    _scannerController.dispose();
    super.dispose();
  }
}
