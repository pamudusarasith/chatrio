import 'dart:convert';
import '../utils/logger.dart';

class QRService {
  static const String _qrPrefix = 'chatrio://';

  // Generate QR data for a chat
  static String generateChatQR(String chatId, String creatorId) {
    Map<String, dynamic> qrData = {
      'type': 'create_chat',
      'creator_id': creatorId,
      'chat_id': chatId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(Duration(minutes: 2))
          .millisecondsSinceEpoch,
    };

    String jsonData = json.encode(qrData);
    String encodedData = base64Encode(utf8.encode(jsonData));

    return '$_qrPrefix$encodedData';
  }

  // Parse QR code data
  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      if (!qrData.startsWith(_qrPrefix)) {
        return null;
      }

      String encodedData = qrData.substring(_qrPrefix.length);
      String jsonData = utf8.decode(base64Decode(encodedData));
      Map<String, dynamic> parsedData = json.decode(jsonData);

      return parsedData;
    } catch (e) {
      AppLogger.error('Error parsing QR data', e);
      return null;
    }
  }

  // Validate QR data for chat
  static bool isValidChatQR(Map<String, dynamic> qrData) {
    if (qrData['type'] != 'create_chat') return false;
    if (qrData['creator_id'] == null || qrData['creator_id'].isEmpty) {
      return false;
    }
    if (qrData['chat_id'] == null || qrData['chat_id'].isEmpty) {
      return false;
    }

    // Check if QR has expired (if expires_at is provided)
    if (qrData['expires_at'] != null) {
      int expiresAt = qrData['expires_at'] as int;
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return false;
      }
    }

    return true;
  }

  // Extract chat ID from QR data
  static String? getChatIdFromQR(String qrData) {
    Map<String, dynamic>? parsedData = parseQRData(qrData);
    if (parsedData == null || !isValidChatQR(parsedData)) {
      return null;
    }

    return parsedData['chat_id'] as String?;
  }

  // Check if QR code is for this app
  static bool isChatrioQR(String qrData) {
    return qrData.startsWith(_qrPrefix);
  }
}
