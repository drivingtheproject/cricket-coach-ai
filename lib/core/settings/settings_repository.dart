import 'package:sqflite/sqflite.dart';

/// Per-user settings stored as key/value text in SQLite.
class SettingsRepository {
  const SettingsRepository(this._db);

  final Database _db;

  Future<String?> get(String userId, String key) async {
    final rows = await _db.query(
      'user_settings',
      columns: ['value'],
      where: 'user_id = ? AND key = ?',
      whereArgs: [userId, key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value']! as String;
  }

  Future<void> set(String userId, String key, String value) async {
    await _db.insert(
      'user_settings',
      {'user_id': userId, 'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(String userId, String key) async {
    await _db.delete(
      'user_settings',
      where: 'user_id = ? AND key = ?',
      whereArgs: [userId, key],
    );
  }
}
