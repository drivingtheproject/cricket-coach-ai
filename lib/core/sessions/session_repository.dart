import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'session.dart';

/// Reads and writes sessions in the local SQLite database.
class SessionRepository {
  SessionRepository(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Database _db;
  final DateTime Function() _now;

  /// Ticks after every write so that lists can reload.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<void> insert(Session session) async {
    await _db.insert('sessions', session.toRow());
    _changed();
  }

  /// Saves a local edit: bumps `updatedAt` and marks the row for sync.
  Future<Session> save(Session session) async {
    final updated = session.copyWith(
      updatedAt: _now(),
      syncState: SyncState.pending,
    );
    await _db.update(
      'sessions',
      updated.toRow(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    _changed();
    return updated;
  }

  Future<Session?> getById(String id) async {
    final rows = await _db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Session.fromRow(rows.first);
  }

  /// A user's sessions, newest first, without deleted ones.
  Future<List<Session>> listForUser(String userId) async {
    final rows = await _db.query(
      'sessions',
      where: 'user_id = ? AND deleted = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Session.fromRow).toList();
  }

  /// Hides the session and drops its pose data. The row stays as a tombstone
  /// until the deletion has been synced.
  Future<void> softDelete(String id) async {
    await _db.update(
      'sessions',
      {
        'deleted': 1,
        'updated_at': _now().millisecondsSinceEpoch,
        'sync_state': SyncState.pending.name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.delete('session_poses', where: 'session_id = ?', whereArgs: [id]);
    _changed();
  }

  Future<void> savePoses(String sessionId, String framesJson) async {
    await _db.insert(
      'session_poses',
      {'session_id': sessionId, 'frames_json': framesJson},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> loadPoses(String sessionId) async {
    final rows = await _db.query(
      'session_poses',
      columns: ['frames_json'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['frames_json']! as String;
  }

  /// Rows with local changes not yet synced, including deletions.
  Future<List<Session>> pendingSync(String userId) async {
    final rows = await _db.query(
      'sessions',
      where: 'user_id = ? AND sync_state = ?',
      whereArgs: [userId, SyncState.pending.name],
      orderBy: 'updated_at ASC',
    );
    return rows.map(Session.fromRow).toList();
  }

  Future<void> markSynced(Iterable<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(
        'sessions',
        {'sync_state': SyncState.synced.name},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
    _changed();
  }

  /// Marks sessions as synced, skipping any that were edited again after
  /// the copies in [pushed] were read.
  Future<void> markSyncedIfUnchanged(List<Session> pushed) async {
    if (pushed.isEmpty) return;
    final batch = _db.batch();
    for (final session in pushed) {
      batch.update(
        'sessions',
        {'sync_state': SyncState.synced.name},
        where: 'id = ? AND updated_at = ?',
        whereArgs: [session.id, session.updatedAt.millisecondsSinceEpoch],
      );
    }
    await batch.commit(noResult: true);
    _changed();
  }

  /// Stores a session exactly as the cloud has it, replacing any local copy,
  /// and marks it synced. The clip path is kept from the local copy because
  /// clips do not sync.
  Future<void> applyFromCloud(Session incoming) async {
    final local = await getById(incoming.id);
    final row = incoming.copyWith(syncState: SyncState.synced).toRow()
      ..['video_path'] = local?.videoPath;
    // An update, not a replace: replacing the row would cascade-delete the
    // session's pose data.
    if (local == null) {
      await _db.insert('sessions', row);
    } else {
      await _db.update(
        'sessions',
        row,
        where: 'id = ?',
        whereArgs: [incoming.id],
      );
    }
    if (incoming.deleted) {
      await _db.delete(
        'session_poses',
        where: 'session_id = ?',
        whereArgs: [incoming.id],
      );
    }
    _changed();
  }

  void _changed() => changes.value++;
}
