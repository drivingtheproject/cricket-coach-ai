import 'package:cricket_coach_ai/core/sessions/session.dart';
import 'package:cricket_coach_ai/core/sessions/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_database.dart';

Session buildSession(
  String id, {
  String userId = 'user-1',
  int createdAtMs = 1000,
  Discipline discipline = Discipline.batting,
}) {
  final created = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
  return Session(
    id: id,
    userId: userId,
    title: 'Session $id',
    discipline: discipline,
    handedness: Handedness.right,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  late Database db;
  late SessionRepository repository;
  var clock = DateTime.fromMillisecondsSinceEpoch(5000);

  setUp(() async {
    db = await openTestDatabase();
    await insertTestUser(db);
    clock = DateTime.fromMillisecondsSinceEpoch(5000);
    repository = SessionRepository(db, now: () => clock);
  });

  tearDown(() => db.close());

  test('a session round-trips through the database unchanged', () async {
    final original = buildSession('a').copyWith(
      videoPath: 'videos/a.mp4',
      durationMs: 6200,
      analysisJson: '{"metrics":[]}',
      feedbackJson: '{"summary":"ok"}',
      coachProvider: 'claude',
      notes: 'Net session',
      score: 72.5,
    );
    await repository.insert(original);

    final loaded = await repository.getById('a');

    expect(loaded, isNotNull);
    expect(loaded!.toRow(), original.toRow());
    expect(loaded.discipline, Discipline.batting);
    expect(loaded.handedness, Handedness.right);
    expect(loaded.syncState, SyncState.pending);
  });

  test('getById returns null for an unknown id', () async {
    expect(await repository.getById('missing'), isNull);
  });

  test('listForUser returns newest first and only that user', () async {
    await insertTestUser(db, id: 'user-2');
    await repository.insert(buildSession('old', createdAtMs: 1000));
    await repository.insert(buildSession('new', createdAtMs: 3000));
    await repository.insert(buildSession('mid', createdAtMs: 2000));
    await repository.insert(buildSession('other', userId: 'user-2'));

    final ids = (await repository.listForUser('user-1')).map((s) => s.id);

    expect(ids, ['new', 'mid', 'old']);
  });

  test('save bumps updatedAt and marks the row pending', () async {
    await repository.insert(buildSession('a'));
    await repository.markSynced(['a']);

    final saved = await repository.save(
      (await repository.getById('a'))!.copyWith(notes: 'Head fell over'),
    );
    final loaded = await repository.getById('a');

    expect(saved.updatedAt, clock);
    expect(loaded!.notes, 'Head fell over');
    expect(loaded.updatedAt, clock);
    expect(loaded.syncState, SyncState.pending);
    expect(loaded.createdAt, DateTime.fromMillisecondsSinceEpoch(1000));
  });

  test('softDelete hides the session but keeps a tombstone to sync', () async {
    await repository.insert(buildSession('a'));
    await repository.savePoses('a', '[]');
    await repository.markSynced(['a']);

    await repository.softDelete('a');

    expect(await repository.listForUser('user-1'), isEmpty);
    expect(await repository.loadPoses('a'), isNull);
    final pending = await repository.pendingSync('user-1');
    expect(pending.single.id, 'a');
    expect(pending.single.deleted, isTrue);
  });

  test('pose data is stored per session and can be replaced', () async {
    await repository.insert(buildSession('a'));

    expect(await repository.loadPoses('a'), isNull);
    await repository.savePoses('a', '[1]');
    await repository.savePoses('a', '[2]');

    expect(await repository.loadPoses('a'), '[2]');
  });

  test('markSynced clears rows from the pending list', () async {
    await repository.insert(buildSession('a'));
    await repository.insert(buildSession('b'));

    await repository.markSynced(['a']);

    final pending = await repository.pendingSync('user-1');
    expect(pending.map((s) => s.id), ['b']);
  });

  test('every write ticks the change notifier', () async {
    var ticks = 0;
    repository.changes.addListener(() => ticks++);

    await repository.insert(buildSession('a'));
    await repository.save((await repository.getById('a'))!);
    await repository.softDelete('a');

    expect(ticks, 3);
  });

  test('deleting a user removes their sessions and pose data', () async {
    await repository.insert(buildSession('a'));
    await repository.savePoses('a', '[]');

    await db.delete('users', where: 'id = ?', whereArgs: ['user-1']);

    expect(await db.query('sessions'), isEmpty);
    expect(await db.query('session_poses'), isEmpty);
  });
}
