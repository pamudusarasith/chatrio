class ChatMessage {
  final String messageId;
  final String sender;
  final String recipient;
  final String text;
  final int timestamp;
  final String sessionId;

  ChatMessage({
    required this.messageId,
    required this.sender,
    required this.recipient,
    required this.text,
    required this.timestamp,
    required this.sessionId,
  });

  factory ChatMessage.fromJson(String messageId, Map<String, dynamic> json) {
    return ChatMessage(
      messageId: messageId,
      sender: json['sender'] ?? '',
      recipient: json['recipient'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      sessionId: json['session_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'recipient': recipient,
      'text': text,
      'timestamp': timestamp,
      'session_id': sessionId,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'sender': sender,
      'recipient': recipient,
      'text': text,
      'timestamp': timestamp,
      'session_id': sessionId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['message_id'] as String,
      sender: map['sender'] as String,
      recipient: map['recipient'] as String,
      text: map['text'] as String,
      timestamp: map['timestamp'] as int,
      sessionId: map['session_id'] as String,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(messageId: $messageId, sender: $sender, recipient: $recipient, text: $text, timestamp: $timestamp, sessionId: $sessionId)';
  }
}
