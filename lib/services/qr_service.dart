import 'dart:convert';

class QRService {
  static const String _qrPrefix = 'chatrio://';

  // Generate QR data for a chat session
  static String generateSessionQR(String sessionId, String creatorId) {
    Map<String, dynamic> qrData = {
      'type': 'chat_session',
      'creator_id': creatorId,
      'session_id': sessionId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(Duration(minutes: 10))
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
      print('Error parsing QR data: $e');
      return null;
    }
  }

  // Validate QR data for chat session
  static bool isValidSessionQR(Map<String, dynamic> qrData) {
    if (qrData['type'] != 'chat_session') return false;
    if (qrData['creator_id'] == null || qrData['creator_id'].isEmpty) {
      return false;
    }
    if (qrData['session_id'] == null || qrData['session_id'].isEmpty) {
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

  // Extract session ID from QR data
  static String? getSessionIdFromQR(String qrData) {
    Map<String, dynamic>? parsedData = parseQRData(qrData);
    if (parsedData == null || !isValidSessionQR(parsedData)) {
      return null;
    }

    return parsedData['session_id'] as String?;
  }

  // Check if QR code is for this app
  static bool isChatrioQR(String qrData) {
    return qrData.startsWith(_qrPrefix);
  }
}
