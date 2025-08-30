import '../models/extension_request.dart';
import '../database/database_manager.dart';

class ExtensionRepository {
  final DatabaseManager _dbManager = DatabaseManager();

  // Insert extension request
  Future<int> insertRequest(ExtensionRequest request) async {
    final db = await _dbManager.database;
    return await db.insert('extension_requests', request.toMap());
  }

  // Get extension request by session ID
  Future<ExtensionRequest?> getRequest(String sessionId) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'extension_requests',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isEmpty) return null;
    return ExtensionRequest.fromMap(maps.first);
  }

  // Get pending extension requests for a user
  Future<List<ExtensionRequest>> getPendingRequests(String userId) async {
    final db = await _dbManager.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Get pending requests for sessions where the user is a participant but not the requester
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT er.* FROM extension_requests er
      INNER JOIN chat_sessions cs ON er.session_id = cs.session_id
      WHERE er.status = 'pending' 
      AND er.expires_at > ?
      AND er.requester != ?
      AND (cs.creator = ? OR cs.joiner = ?)
    ''',
      [currentTime, userId, userId, userId],
    );

    return List.generate(maps.length, (i) => ExtensionRequest.fromMap(maps[i]));
  }

  // Get all extension requests for sessions where user is a participant
  Future<List<ExtensionRequest>> getUserRequests(String userId) async {
    final db = await _dbManager.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT er.* FROM extension_requests er
      INNER JOIN chat_sessions cs ON er.session_id = cs.session_id
      WHERE (cs.creator = ? OR cs.joiner = ?)
      ORDER BY er.requested_at DESC
    ''',
      [userId, userId],
    );

    return List.generate(maps.length, (i) => ExtensionRequest.fromMap(maps[i]));
  }

  // Update extension request
  Future<int> updateRequest(ExtensionRequest request) async {
    final db = await _dbManager.database;
    return await db.update(
      'extension_requests',
      request.toMap(),
      where: 'session_id = ?',
      whereArgs: [request.sessionId],
    );
  }

  // Delete extension request
  Future<int> deleteRequest(String sessionId) async {
    final db = await _dbManager.database;
    return await db.delete(
      'extension_requests',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // Delete expired extension requests
  Future<int> deleteExpiredRequests() async {
    final db = await _dbManager.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return await db.delete(
      'extension_requests',
      where: 'expires_at <= ?',
      whereArgs: [currentTime],
    );
  }

  // Update request status
  Future<int> updateRequestStatus(
    String sessionId,
    String status, {
    int? timestamp,
  }) async {
    final db = await _dbManager.database;

    Map<String, dynamic> updates = {'status': status};
    if (timestamp != null) {
      if (status == 'approved') {
        updates['approved_at'] = timestamp;
      } else if (status == 'rejected') {
        updates['rejected_at'] = timestamp;
      }
    }

    return await db.update(
      'extension_requests',
      updates,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }
}
