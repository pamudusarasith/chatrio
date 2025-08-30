class Message {
  final String messageId;
  final String sender;
  final String recipient;
  final String text;
  final int timestamp;
  final String chatId;

  Message({
    required this.messageId,
    required this.sender,
    required this.recipient,
    required this.text,
    required this.timestamp,
    required this.chatId,
  });

  factory Message.fromJson(String messageId, Map<String, dynamic> json) {
    return Message(
      messageId: messageId,
      sender: json['sender'] ?? '',
      recipient: json['recipient'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      chatId: json['chat_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'recipient': recipient,
      'text': text,
      'timestamp': timestamp,
      'chat_id': chatId,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'sender': sender,
      'recipient': recipient,
      'text': text,
      'timestamp': timestamp,
      'chat_id': chatId,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageId: map['message_id'] as String,
      sender: map['sender'] as String,
      recipient: map['recipient'] as String,
      text: map['text'] as String,
      timestamp: map['timestamp'] as int,
      chatId: map['chat_id'] as String,
    );
  }

  @override
  String toString() {
    return 'Message(messageId: $messageId, sender: $sender, recipient: $recipient, text: $text, timestamp: $timestamp, chatId: $chatId)';
  }
}
