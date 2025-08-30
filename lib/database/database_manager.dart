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

    // Chat sessions table
    await db.execute('''
      CREATE TABLE chat_sessions(
        session_id TEXT PRIMARY KEY,
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
      CREATE TABLE chat_messages(
        message_id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        recipient TEXT NOT NULL,
        text TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        session_id TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (session_id) ON DELETE CASCADE
      )
    ''');

    // Extension requests table
    await db.execute('''
      CREATE TABLE extension_requests(
        session_id TEXT PRIMARY KEY,
        requester TEXT NOT NULL,
        additional_minutes INTEGER NOT NULL,
        requested_at INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        expires_at INTEGER NOT NULL,
        approved_at INTEGER,
        rejected_at INTEGER,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (session_id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_messages_recipient ON chat_messages(recipient)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_session ON chat_messages(session_id)',
    );
    await db.execute(
      'CREATE INDEX idx_sessions_creator ON chat_sessions(creator)',
    );
    await db.execute(
      'CREATE INDEX idx_sessions_joiner ON chat_sessions(joiner)',
    );
    await db.execute(
      'CREATE INDEX idx_extension_requests_status ON extension_requests(status)',
    );
  }

  // Cleanup Methods
  Future<void> cleanupExpiredData() async {
    final db = await database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Delete expired sessions
    await db.delete(
      'chat_sessions',
      where: 'expires_at <= ?',
      whereArgs: [currentTime],
    );

    // Delete expired extension requests
    await db.delete(
      'extension_requests',
      where: 'expires_at <= ?',
      whereArgs: [currentTime],
    );
  }
}
