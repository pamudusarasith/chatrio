import '../models/chat_session.dart';
import '../database/database_manager.dart';

class SessionRepository {
  final DatabaseManager _dbManager = DatabaseManager();

  // Insert chat session
  Future<int> insertSession(ChatSession session) async {
    final db = await _dbManager.database;
    return await db.insert('chat_sessions', session.toMap());
  }

  // Get chat session by ID
  Future<ChatSession?> getSession(String sessionId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isEmpty) return null;
    return ChatSession.fromMap(maps.first);
  }

  // Get all sessions for a user
  Future<List<ChatSession>> getUserSessions(String userId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      where: 'creator = ? OR joiner = ?',
      whereArgs: [userId, userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => ChatSession.fromMap(maps[i]));
  }

  // Get active sessions for a user
  Future<List<ChatSession>> getActiveSessions(String userId) async {
    final db = await _dbManager.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      where: '(creator = ? OR joiner = ?) AND is_active = 1 AND expires_at > ?',
      whereArgs: [userId, userId, currentTime],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => ChatSession.fromMap(maps[i]));
  }

  // Update chat session
  Future<int> updateSession(ChatSession session) async {
    final db = await _dbManager.database;
    return await db.update(
      'chat_sessions',
      session.toMap(),
      where: 'session_id = ?',
      whereArgs: [session.sessionId],
    );
  }

  // Set session nickname (local only)
  Future<int> setSessionNickname(String sessionId, String nickname) async {
    final db = await _dbManager.database;
    return await db.update(
      'chat_sessions',
      {'nickname': nickname},
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // Get session nickname
  Future<String?> getSessionNickname(String sessionId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      columns: ['nickname'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isEmpty) return null;
    return maps.first['nickname'] as String?;
  }

  // Delete chat session
  Future<int> deleteSession(String sessionId) async {
    final db = await _dbManager.database;
    return await db.delete(
      'chat_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // Delete expired sessions
  Future<int> deleteExpiredSessions() async {
    final db = await _dbManager.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return await db.delete(
      'chat_sessions',
      where: 'expires_at <= ?',
      whereArgs: [currentTime],
    );
  }
}
