class User {
  final String id;
  final DateTime createdAt;

  User({required this.id, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {'id': id, 'created_at': createdAt.toIso8601String()};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() => 'User(id: $id, createdAt: $createdAt)';
}
