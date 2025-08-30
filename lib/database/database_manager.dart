import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  factory DatabaseManager() => _instance;
  DatabaseManager._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chatrio.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table - only stores current user
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
      )
    ''');

    // Chats table
    await db.execute('''
      CREATE TABLE chats(
        chat_id TEXT PRIMARY KEY,
        creator TEXT NOT NULL,
        joiner TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        nickname TEXT
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE messages(
        message_id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        recipient TEXT NOT NULL,
        text TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        chat_id TEXT NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chats (chat_id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_messages_recipient ON messages(recipient)',
    );
    await db.execute('CREATE INDEX idx_messages_chat ON messages(chat_id)');
    await db.execute('CREATE INDEX idx_chats_creator ON chats(creator)');
    await db.execute('CREATE INDEX idx_chats_joiner ON chats(joiner)');
  }

  // Cleanup Methods
  Future<void> cleanupExpiredData() async {
    final db = await database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Delete expired chats
    await db.delete(
      'chats',
      where: 'expires_at <= ?',
      whereArgs: [currentTime],
    );
  }
}
