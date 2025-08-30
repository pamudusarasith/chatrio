class User {
  final String id;
  final int createdAt;

  User({required this.id, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {'id': id, 'created_at': createdAt};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(id: map['id'] as String, createdAt: map['created_at'] as int);
  }

  // Get DateTime from timestamp
  DateTime get createdAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createdAt);

  @override
  String toString() =>
      'User(id: $id, createdAt: ${createdAtDateTime.toIso8601String()})';
}
