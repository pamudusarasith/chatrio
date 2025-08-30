import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/qr_service.dart';

class ScanQRViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  late MobileScannerController _scannerController;
  late ChatService _chatService;
  StreamSubscription? _sessionSubscription;

  // State variables
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isWaitingForActivation = false;
  String? _currentUserId;
  String? _errorMessage;
  Map<String, dynamic>? _parsedQRData;
  String? _sessionId;
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
  String? get sessionId => _sessionId;
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
    // Log to console as requested
    print('QR Code Scanned: $data');

    // Reset validation state
    _isValidQR = false;
    _sessionId = null;
    _parsedQRData = null;

    // Check if it's a Chatrio QR code using QR service
    if (QRService.isChatrioQR(data)) {
      // Parse QR data using QR service
      _parsedQRData = QRService.parseQRData(data);

      if (_parsedQRData != null) {
        print('Parsed QR Data: $_parsedQRData');

        // Validate the QR data using QR service
        if (QRService.isValidSessionQR(_parsedQRData!)) {
          _isValidQR = true;
          _sessionId = QRService.getSessionIdFromQR(data);

          print('Valid Chatrio QR detected!');
          print('Session ID: $_sessionId');
          print('Creator ID: ${_parsedQRData!['creator_id']}');
          print('Timestamp: ${_parsedQRData!['timestamp']}');

          if (_parsedQRData!['expires_at'] != null) {
            print('Expires at: ${_parsedQRData!['expires_at']}');
          }

          _clearError();

          // Automatically create the session
          _createSession();
        } else {
          print('Invalid or expired Chatrio QR code');
          _setError('Invalid or expired QR code');
        }
      } else {
        print('Failed to parse Chatrio QR code');
        _setError('Invalid QR code format');
      }
    } else {
      print('Not a Chatrio QR code: $data');
      _setError('This is not a valid Chatrio QR code');
    }

    notifyListeners();
  }

  // Create session (called automatically when valid QR is scanned)
  Future<void> _createSession() async {
    if (!_isValidQR || _sessionId == null || _parsedQRData == null) {
      return;
    }

    _isCreating = true;
    _setLoading(true);

    try {
      print('Automatically creating session...');

      // Use chat service to create the session
      bool success = await _chatService.createSession(
        sessionId: _sessionId!,
        creatorId: _parsedQRData!['creator_id'],
        createdAt: _parsedQRData!['created_at'],
        expiresAt: _parsedQRData!['expires_at'],
      );

      if (success) {
        print('Successfully created session: $_sessionId');
        _clearError();

        // Now wait for the session to be activated by the generator
        _waitForSessionActivation();
      } else {
        print('Failed to create session');
        _setError('Failed to create session.');
      }
    } catch (e) {
      print('Error joining session: $e');
      _setError('Error joining session: $e');
    } finally {
      _isCreating = false;
      _setLoading(false);
    }
  }

  // Wait for the session to be activated by the generator
  void _waitForSessionActivation() {
    if (_sessionId == null) return;

    _isWaitingForActivation = true;
    _isCreating = false;
    notifyListeners();

    print('Waiting for generator to activate session...');

    _sessionSubscription = _chatService.listenToSessionChanges(_sessionId!, (
      joinedUserId,
      isActive,
    ) {
      if (isActive) {
        print('Session activated! Both users confirmed.');
        _isWaitingForActivation = false;
        _setLoading(false);
        _clearError();

        // Session is now active and saved locally by ChatService
        _stopListening();
      }
    });
  }

  // Stop listening to session changes
  void _stopListening() {
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
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
