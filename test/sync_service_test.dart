import 'package:cricket_coach_ai/core/sessions/session.dart';
import 'package:cricket_coach_ai/core/sessions/session_repository.dart';
import 'package:cricket_coach_ai/core/settings/settings_repository.dart';
import 'package:cricket_coach_ai/core/sync/cloud_backend.dart';
import 'package:cricket_coach_ai/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_database.dart';

/// An in-memory cloud keyed by session id.
class FakeBackend implements CloudBackend {
  final Map<String, Session> store = {};
  final List<DateTime?> pullsSince = [];
  bool failPush = false;
  bool failPull = false;
  Future<void> Function()? beforePushReturns;

  @override
  bool get isConfigured => true;

  @override
  Future<void> push(String userId, List<Session> sessions) async {
    if (failPush) throw Exception('offline');
    for (final session in sessions) {
      store[session.id] = session;
    }
    await beforePushReturns?.call();
  }

  @override
  Future<List<Session>> pull(String userId, {DateTime? since}) async {
    pullsSince.add(since);
    if (failPull) throw Exception('offline');
    return store.values
        .where((s) => since == null || s.updatedAt.isAfter(since))
        .toList();
  }
}

DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

Session session(String id, {int updatedMs = 1000, String title = 'Local'}) =>
    Session(
      id: id,
      userId: 'user-1',
      title: title,
      discipline: Discipline.batting,
      handedness: Handedness.right,
      createdAt: at(1000),
      updatedAt: at(updatedMs),
    );

void main() {
  const user = 'user-1';
  late Database db;
  late SessionRepository sessions;
  late FakeBackend backend;
  late SyncService sync;
  var clock = at(10000);

  setUp(() async {
    db = await openTestDatabase();
    await insertTestUser(db);
    clock = at(10000);
    sessions = SessionRepository(db, now: () => clock);
    backend = FakeBackend();
    sync = SyncService(
      sessions: sessions,
      settings: SettingsRepository(db),
      backend: backend,
      now: () => clock,
    );
  });

  tearDown(() => db.close());

  test('without a cloud project sync is refused and nothing changes',
      () async {
    final offline = SyncService(
      sessions: sessions,
      settings: SettingsRepository(db),
      backend: const NoCloudBackend(),
    );
    await sessions.insert(session('a'));

    expect(offline.isConfigured, isFalse);
    await expectLater(offline.sync(user), throwsA(isA<SyncException>()));
    expect(await offline.pendingCount(user), 1);
    expect(await offline.lastSyncedAt(user), isNull);
  });

  test('pushes pending sessions and marks them synced', () async {
    await sessions.insert(session('a'));
    await sessions.insert(session('b'));
    expect(await sync.pendingCount(user), 2);

    final report = await sync.sync(user);

    expect(report.pushed, 2);
    expect(report.pulled, 0);
    expect(backend.store.keys, containsAll(['a', 'b']));
    expect(await sync.pendingCount(user), 0);
    expect((await sessions.getById('a'))!.syncState, SyncState.synced);
    expect(await sync.lastSyncedAt(user), at(10000));
  });

  test('a local edit after syncing is pending again', () async {
    await sessions.insert(session('a'));
    await sync.sync(user);

    clock = at(20000);
    await sessions.save((await sessions.getById('a'))!.copyWith(notes: 'new'));

    expect(await sync.pendingCount(user), 1);
    await sync.sync(user);
    expect(backend.store['a']!.notes, 'new');
    expect(await sync.pendingCount(user), 0);
  });

  test('deletions are pushed as tombstones', () async {
    await sessions.insert(session('a'));
    await sync.sync(user);

    clock = at(20000);
    await sessions.softDelete('a');
    final report = await sync.sync(user);

    expect(report.pushed, 1);
    expect(backend.store['a']!.deleted, isTrue);
  });

  test('pulls sessions made on another device', () async {
    backend.store['remote'] = session('remote', title: 'From tablet');

    final report = await sync.sync(user);

    expect(report.pulled, 1);
    final pulled = (await sessions.getById('remote'))!;
    expect(pulled.title, 'From tablet');
    expect(pulled.syncState, SyncState.synced);
    expect(await sync.pendingCount(user), 0);
  });

  test('the newer edit wins, and pose data survives', () async {
    await sessions.insert(session('a').copyWith(videoPath: 'videos/a.mp4'));
    await sessions.savePoses('a', '[]');
    await sync.sync(user);
    backend.store['a'] = session('a', updatedMs: 50000, title: 'Cloud edit');

    clock = at(60000);
    final report = await sync.sync(user);

    expect(report.pulled, 1);
    final merged = (await sessions.getById('a'))!;
    expect(merged.title, 'Cloud edit');
    expect(merged.videoPath, 'videos/a.mp4');
    expect(await sessions.loadPoses('a'), '[]');
  });

  test('an older cloud copy does not overwrite a newer local one', () async {
    await sessions.insert(session('a', updatedMs: 9000, title: 'Local edit'));
    await sync.sync(user);
    backend.store['a'] = session('a', updatedMs: 2000, title: 'Stale');

    final report = await sync.sync(user);

    expect(report.pulled, 0);
    expect((await sessions.getById('a'))!.title, 'Local edit');
  });

  test('a deletion made elsewhere removes the session here', () async {
    await sessions.insert(session('a'));
    await sessions.savePoses('a', '[]');
    await sync.sync(user);
    backend.store['a'] =
        session('a', updatedMs: 50000).copyWith(deleted: true);

    await sync.sync(user);

    expect(await sessions.listForUser(user), isEmpty);
    expect(await sessions.loadPoses('a'), isNull);
  });

  test('another user\'s sessions are never applied', () async {
    backend.store['x'] = Session(
      id: 'x',
      userId: 'someone-else',
      title: 'Not mine',
      discipline: Discipline.batting,
      handedness: Handedness.right,
      createdAt: at(1000),
      updatedAt: at(1000),
    );

    final report = await sync.sync(user);

    expect(report.pulled, 0);
    expect(await sessions.getById('x'), isNull);
  });

  test('later syncs only ask for changes since the last one', () async {
    await sync.sync(user);
    clock = at(30000);
    await sync.sync(user);

    expect(backend.pullsSince, [null, at(10000)]);
  });

  test('a failed push keeps everything pending', () async {
    await sessions.insert(session('a'));
    backend.failPush = true;

    await expectLater(
      sync.sync(user),
      throwsA(
        isA<SyncException>().having(
          (e) => e.message,
          'message',
          contains('could not be reached'),
        ),
      ),
    );

    expect(await sync.pendingCount(user), 1);
    expect(await sync.lastSyncedAt(user), isNull);
  });

  test('a failed pull does not move the last-synced time', () async {
    backend.failPull = true;
    await expectLater(sync.sync(user), throwsA(isA<SyncException>()));
    expect(await sync.lastSyncedAt(user), isNull);
  });

  test('a session edited while it was being pushed stays pending', () async {
    await sessions.insert(session('a'));
    backend.beforePushReturns = () async {
      clock = at(15000);
      await sessions.save((await sessions.getById('a'))!.copyWith(notes: 'x'));
    };

    await sync.sync(user);

    expect(await sync.pendingCount(user), 1);
  });
}
