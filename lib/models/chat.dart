class Chat {
  final String chatId;
  final String creator;
  final String joiner;
  final int createdAt;
  final int expiresAt;
  final bool isActive;
  final String? nickname;

  Chat({
    required this.chatId,
    required this.creator,
    required this.joiner,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    this.nickname,
  });

  factory Chat.fromJson(String chatId, Map<String, dynamic> json) {
    return Chat(
      chatId: chatId,
      creator: json['creator'] ?? '',
      joiner: json['joiner'] ?? '',
      createdAt: json['created_at'] ?? 0,
      expiresAt: json['expires_at'] ?? 0,
      isActive: json['is_active'] ?? true,
      nickname: null, // nickname is local only, not from Firebase
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creator': creator,
      'joiner': joiner,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'creator': creator,
      'joiner': joiner,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'is_active': isActive ? 1 : 0,
      'nickname': nickname,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      chatId: map['chat_id'] as String,
      creator: map['creator'] as String,
      joiner: map['joiner'] as String,
      createdAt: map['created_at'] as int,
      expiresAt: map['expires_at'] as int,
      isActive: (map['is_active'] as int) == 1,
      nickname: map['nickname'] as String?,
    );
  }

  bool isParticipant(String userId) {
    return creator == userId || joiner == userId;
  }

  bool isExpired() {
    return DateTime.now().millisecondsSinceEpoch > expiresAt;
  }

  bool isValid() {
    return isActive && !isExpired();
  }

  String getOtherParticipant(String userId) {
    return creator == userId ? joiner : creator;
  }

  // Get display name (nickname if available, otherwise short user ID)
  String getDisplayName(String currentUserId) {
    if (nickname != null && nickname!.isNotEmpty) {
      return nickname!;
    }
    String otherUser = getOtherParticipant(currentUserId);
    // Return last 8 characters of the other user's ID
    return otherUser.length > 8
        ? otherUser.substring(otherUser.length - 8)
        : otherUser;
  }

  // Create a copy with updated fields
  Chat copyWith({
    String? chatId,
    String? creator,
    String? joiner,
    int? createdAt,
    int? expiresAt,
    bool? isActive,
    String? nickname,
  }) {
    return Chat(
      chatId: chatId ?? this.chatId,
      creator: creator ?? this.creator,
      joiner: joiner ?? this.joiner,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      nickname: nickname ?? this.nickname,
    );
  }

  @override
  String toString() {
    return 'Chat(chatId: $chatId, creator: $creator, joiner: $joiner, createdAt: $createdAt, expiresAt: $expiresAt, isActive: $isActive, nickname: $nickname)';
  }
}
