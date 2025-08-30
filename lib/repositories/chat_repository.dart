import '../models/chat.dart';
import '../database/database_manager.dart';

class ChatRepository {
  final DatabaseManager _dbManager = DatabaseManager();

  // Insert chat
  Future<int> insertChat(Chat chat) async {
    final db = await _dbManager.database;
    return await db.insert('chats', chat.toMap());
  }

  // Get chat by ID
  Future<Chat?> getChat(String chatId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );

    if (maps.isEmpty) return null;
    return Chat.fromMap(maps.first);
  }

  // Get all chats for a user
  Future<List<Chat>> getUserChats(String userId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      where: 'creator = ? OR joiner = ?',
      whereArgs: [userId, userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => Chat.fromMap(maps[i]));
  }

  // Get active chats for a user
  Future<List<Chat>> getActiveChats(String userId) async {
    final db = await _dbManager.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      where: '(creator = ? OR joiner = ?) AND is_active = 1 AND expires_at > ?',
      whereArgs: [userId, userId, currentTime],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => Chat.fromMap(maps[i]));
  }

  // Update chat
  Future<int> updateChat(Chat chat) async {
    final db = await _dbManager.database;
    return await db.update(
      'chats',
      chat.toMap(),
      where: 'chat_id = ?',
      whereArgs: [chat.chatId],
    );
  }

  // Set chat nickname (local only)
  Future<int> setChatNickname(String chatId, String nickname) async {
    final db = await _dbManager.database;
    return await db.update(
      'chats',
      {'nickname': nickname},
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }

  // Get chat nickname
  Future<String?> getChatNickname(String chatId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      columns: ['nickname'],
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );

    if (maps.isEmpty) return null;
    return maps.first['nickname'] as String?;
  }

  // Delete chat
  Future<int> deleteChat(String chatId) async {
    final db = await _dbManager.database;
    return await db.delete('chats', where: 'chat_id = ?', whereArgs: [chatId]);
  }

  // Delete expired chats
  Future<int> deleteExpiredChats() async {
    final db = await _dbManager.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return await db.delete(
      'chats',
      where: 'expires_at <= ?',
      whereArgs: [currentTime],
    );
  }
}
