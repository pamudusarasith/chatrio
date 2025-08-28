import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../database/database_helper.dart';

class UserRepository {
  final DatabaseHelper _databaseHelper;

  UserRepository(this._databaseHelper);

  Future<User?> getCurrentUser() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveUser(User user) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteUser(String userId) async {
    final db = await _databaseHelper.database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> clearAllUsers() async {
    final db = await _databaseHelper.database;
    await db.delete('users');
  }
}
