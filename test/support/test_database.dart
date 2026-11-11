import 'package:cricket_coach_ai/core/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A fresh in-memory database with the app's real schema.
Future<Database> openTestDatabase() {
  sqfliteFfiInit();
  return AppDatabase.open(
    databaseFactoryFfi,
    inMemoryDatabasePath,
    singleInstance: false,
  );
}

/// Inserts a user row so that sessions can reference it.
Future<void> insertTestUser(Database db, {String id = 'user-1'}) {
  return db.insert('users', {
    'id': id,
    'email': '$id@example.com',
    'display_name': 'Test Player',
    'password_hash': 'x',
    'created_at': 0,
  });
}
