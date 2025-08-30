import '../models/user.dart';
import '../database/database_manager.dart';

class UserRepository {
  final DatabaseManager _dbManager = DatabaseManager();

  // Get or create current user (only current user is stored locally)
  Future<User?> getCurrentUser() async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      limit: 1, // Only one user (current user) should exist
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }

    return null;
  }

  // Save only the current user to database (private method)
  Future<void> _saveCurrentUser(User user) async {
    final db = await _dbManager.database;

    // Clear any existing users first (ensure only current user exists)
    await db.delete('users');

    // Insert current user
    await db.insert('users', user.toMap());
  }

  // Public method to save current user (used by view models)
  Future<void> saveUser(User user) async {
    await _saveCurrentUser(user);
  }
}
