class ExtensionRequest {
  final String chatId;
  final String requester;
  final int additionalMinutes;
  final int requestedAt;
  final String status;
  final int expiresAt;
  final int? approvedAt;
  final int? rejectedAt;

  ExtensionRequest({
    required this.chatId,
    required this.requester,
    required this.additionalMinutes,
    required this.requestedAt,
    required this.status,
    required this.expiresAt,
    this.approvedAt,
    this.rejectedAt,
  });

  factory ExtensionRequest.fromJson(String chatId, Map<String, dynamic> json) {
    return ExtensionRequest(
      chatId: chatId,
      requester: json['requester'] ?? '',
      additionalMinutes: json['additional_minutes'] ?? 0,
      requestedAt: json['requested_at'] ?? 0,
      status: json['status'] ?? 'pending',
      expiresAt: json['expires_at'] ?? 0,
      approvedAt: json['approved_at'],
      rejectedAt: json['rejected_at'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      'requester': requester,
      'additional_minutes': additionalMinutes,
      'requested_at': requestedAt,
      'status': status,
      'expires_at': expiresAt,
    };

    if (approvedAt != null) data['approved_at'] = approvedAt;
    if (rejectedAt != null) data['rejected_at'] = rejectedAt;

    return data;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {
      'chat_id': chatId,
      'requester': requester,
      'additional_minutes': additionalMinutes,
      'requested_at': requestedAt,
      'status': status,
      'expires_at': expiresAt,
    };

    if (approvedAt != null) data['approved_at'] = approvedAt;
    if (rejectedAt != null) data['rejected_at'] = rejectedAt;

    return data;
  }

  factory ExtensionRequest.fromMap(Map<String, dynamic> map) {
    return ExtensionRequest(
      chatId: map['chat_id'] as String,
      requester: map['requester'] as String,
      additionalMinutes: map['additional_minutes'] as int,
      requestedAt: map['requested_at'] as int,
      status: map['status'] as String,
      expiresAt: map['expires_at'] as int,
      approvedAt: map['approved_at'] as int?,
      rejectedAt: map['rejected_at'] as int?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  @override
  String toString() {
    return 'ExtensionRequest(chatId: $chatId, requester: $requester, additionalMinutes: $additionalMinutes, status: $status)';
  }
}
