import '../sessions/session.dart';
import '../sessions/session_repository.dart';
import '../settings/settings_repository.dart';
import 'cloud_backend.dart';

class SyncReport {
  const SyncReport({required this.pushed, required this.pulled});

  /// Local changes sent to the cloud.
  final int pushed;

  /// Cloud changes applied on this phone.
  final int pulled;
}

/// Two-way sync of session records between this phone and the cloud.
///
/// Local changes are pushed first, then cloud changes are pulled. When both
/// sides changed the same session, the one edited last wins.
class SyncService {
  SyncService({
    required this.sessions,
    required this.settings,
    required this.backend,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SessionRepository sessions;
  final SettingsRepository settings;
  final CloudBackend backend;
  final DateTime Function() _now;

  static const String _lastSyncKey = 'sync.last_at';

  bool get isConfigured => backend.isConfigured;

  Future<int> pendingCount(String userId) async =>
      (await sessions.pendingSync(userId)).length;

  Future<DateTime?> lastSyncedAt(String userId) async {
    final value = await settings.get(userId, _lastSyncKey);
    final ms = value == null ? null : int.tryParse(value);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Throws [SyncException] when sync is not set up or the cloud cannot be
  /// reached. Changes that were not sent stay pending for the next attempt.
  Future<SyncReport> sync(String userId) async {
    if (!backend.isConfigured) {
      throw const SyncException('Cloud sync is not set up in this version.');
    }
    final startedAt = _now();
    final since = await lastSyncedAt(userId);

    final pending = await sessions.pendingSync(userId);
    final List<Session> remote;
    try {
      if (pending.isNotEmpty) await backend.push(userId, pending);
      await sessions.markSyncedIfUnchanged(pending);
      remote = await backend.pull(userId, since: since);
    } on SyncException {
      rethrow;
    } on Exception {
      throw const SyncException(
        'The cloud could not be reached. Your changes are saved on this '
        'phone and will sync next time.',
      );
    }

    var pulled = 0;
    for (final incoming in remote) {
      if (incoming.userId != userId) continue;
      final local = await sessions.getById(incoming.id);
      final localIsNewer =
          local != null && !incoming.updatedAt.isAfter(local.updatedAt);
      if (localIsNewer) continue;
      await sessions.applyFromCloud(incoming);
      pulled++;
    }

    await settings.set(
      userId,
      _lastSyncKey,
      '${startedAt.millisecondsSinceEpoch}',
    );
    return SyncReport(pushed: pending.length, pulled: pulled);
  }
}
