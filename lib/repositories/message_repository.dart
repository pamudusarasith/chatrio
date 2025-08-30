import '../models/message.dart';
import '../database/database_manager.dart';

class MessageRepository {
  final DatabaseManager _dbManager = DatabaseManager();

  // Insert chat message
  Future<int> insertMessage(Message message) async {
    final db = await _dbManager.database;
    return await db.insert('messages', message.toMap());
  }

  // Get messages for a chat
  Future<List<Message>> getChatMessages(String chatId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  // Get messages for a user (sent or received)
  Future<List<Message>> getUserMessages(String userId, {int? limit}) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'sender = ? OR recipient = ?',
      whereArgs: [userId, userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  // Get recent messages across all chats for a user
  Future<List<Message>> getRecentMessages(
    String userId, {
    int limit = 50,
  }) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.* FROM messages m
      INNER JOIN chats c ON m.chat_id = c.chat_id
      WHERE (c.creator = ? OR c.joiner = ?)
      ORDER BY m.timestamp DESC
      LIMIT ?
    ''',
      [userId, userId, limit],
    );

    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  // Delete a message
  Future<int> deleteMessage(String messageId) async {
    final db = await _dbManager.database;
    return await db.delete(
      'messages',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  // Delete all messages for a chat
  Future<int> deleteChatMessages(String chatId) async {
    final db = await _dbManager.database;
    return await db.delete(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }

  // Get message count for a chat
  Future<int> getChatMessageCount(String chatId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE chat_id = ?',
      [chatId],
    );
    return result.first['count'] as int;
  }

  // Get last message for a chat
  Future<Message?> getLastChatMessage(String chatId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Message.fromMap(maps.first);
  }
}
