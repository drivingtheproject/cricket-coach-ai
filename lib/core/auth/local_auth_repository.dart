import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../util/ids.dart';
import 'auth_repository.dart';
import 'password_hasher.dart';
import 'user.dart';

// Hashing runs on a background isolate so the UI never stalls on it.
String _hashOnIsolate((PasswordHasher, String) args) => args.$1.hash(args.$2);

bool _verifyOnIsolate((PasswordHasher, String, String) args) =>
    args.$1.verify(args.$2, args.$3);

/// Accounts stored in the on-device SQLite database.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(
    this._db, {
    this.hasher = const PasswordHasher(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Database _db;
  final PasswordHasher hasher;
  final DateTime Function() _now;

  static const String _currentUserKey = 'current_user_id';

  @override
  Future<User?> currentUser() async {
    final state = await _db.query(
      'app_state',
      where: 'key = ?',
      whereArgs: [_currentUserKey],
      limit: 1,
    );
    if (state.isEmpty) return null;
    final rows = await _db.query(
      'users',
      where: 'id = ?',
      whereArgs: [state.first['value']],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromRow(rows.first);
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final address = _normalise(email);
    final existing = await _db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [address],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const AuthException(AuthFailure.emailInUse);
    }

    final encoded = await compute(_hashOnIsolate, (hasher, password));
    final user = User(
      id: newId(),
      email: address,
      displayName: displayName.trim(),
      createdAt: _now(),
    );
    await _db.insert('users', {
      'id': user.id,
      'email': user.email,
      'display_name': user.displayName,
      'password_hash': encoded,
      'created_at': user.createdAt.millisecondsSinceEpoch,
    });
    await _remember(user.id);
    return user;
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    final rows = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [_normalise(email)],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }
    final encoded = rows.first['password_hash']! as String;
    final matches = await compute(_verifyOnIsolate, (hasher, password, encoded));
    if (!matches) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }
    final user = User.fromRow(rows.first);
    await _remember(user.id);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _db.delete(
      'app_state',
      where: 'key = ?',
      whereArgs: [_currentUserKey],
    );
  }

  Future<void> _remember(String userId) async {
    await _db.insert(
      'app_state',
      {'key': _currentUserKey, 'value': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static String _normalise(String email) => email.trim().toLowerCase();
}
