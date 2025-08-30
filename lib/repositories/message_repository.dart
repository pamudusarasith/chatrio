import '../models/chat_message.dart';
import '../database/database_manager.dart';

class MessageRepository {
  final DatabaseManager _dbManager = DatabaseManager();

  // Insert chat message
  Future<int> insertMessage(ChatMessage message) async {
    final db = await _dbManager.database;
    return await db.insert('chat_messages', message.toMap());
  }

  // Get messages for a session
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  // Get messages for a user (sent or received)
  Future<List<ChatMessage>> getUserMessages(String userId, {int? limit}) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'sender = ? OR recipient = ?',
      whereArgs: [userId, userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  // Get recent messages across all sessions for a user
  Future<List<ChatMessage>> getRecentMessages(
    String userId, {
    int limit = 50,
  }) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT cm.* FROM chat_messages cm
      INNER JOIN chat_sessions cs ON cm.session_id = cs.session_id
      WHERE (cs.creator = ? OR cs.joiner = ?)
      ORDER BY cm.timestamp DESC
      LIMIT ?
    ''',
      [userId, userId, limit],
    );

    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  // Delete a message
  Future<int> deleteMessage(String messageId) async {
    final db = await _dbManager.database;
    return await db.delete(
      'chat_messages',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  // Delete all messages for a session
  Future<int> deleteSessionMessages(String sessionId) async {
    final db = await _dbManager.database;
    return await db.delete(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // Get message count for a session
  Future<int> getSessionMessageCount(String sessionId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM chat_messages WHERE session_id = ?',
      [sessionId],
    );
    return result.first['count'] as int;
  }

  // Get last message for a session
  Future<ChatMessage?> getLastSessionMessage(String sessionId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ChatMessage.fromMap(maps.first);
  }
}
