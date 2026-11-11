import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens the app's SQLite database and owns its schema.
abstract final class AppDatabase {
  static const int schemaVersion = 1;
  static const String fileName = 'cricket_coach.db';

  /// Opens the database stored on the device.
  static Future<Database> openOnDevice() async {
    final directory = await getDatabasesPath();
    return open(databaseFactory, p.join(directory, fileName));
  }

  /// Opens a database with any factory. Tests pass an in-memory factory.
  static Future<Database> open(
    DatabaseFactory factory,
    String path, {
    bool singleInstance = true,
  }) {
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        singleInstance: singleInstance,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _create(db),
      ),
    );
  }

  static Future<void> _create(Database db) async {
    final batch = db.batch();
    for (final statement in _schemaV1) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
  }

  // Every syncable row carries updated_at, sync_state and a soft-delete flag,
  // so a cloud backend can be added without changing the schema.
  static const List<String> _schemaV1 = [
    '''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL UNIQUE,
      display_name TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE app_state (
      key TEXT PRIMARY KEY,
      value TEXT
    )''',
    '''
    CREATE TABLE user_settings (
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      key TEXT NOT NULL,
      value TEXT NOT NULL,
      PRIMARY KEY (user_id, key)
    )''',
    '''
    CREATE TABLE sessions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      title TEXT NOT NULL,
      discipline TEXT NOT NULL,
      handedness TEXT NOT NULL,
      video_path TEXT,
      duration_ms INTEGER NOT NULL DEFAULT 0,
      analysis_json TEXT,
      feedback_json TEXT,
      coach_provider TEXT,
      notes TEXT NOT NULL DEFAULT '',
      score REAL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      sync_state TEXT NOT NULL DEFAULT 'pending',
      deleted INTEGER NOT NULL DEFAULT 0
    )''',
    'CREATE INDEX idx_sessions_user ON sessions (user_id, created_at DESC)',
    '''
    CREATE TABLE session_poses (
      session_id TEXT PRIMARY KEY REFERENCES sessions(id) ON DELETE CASCADE,
      frames_json TEXT NOT NULL
    )''',
  ];
}
