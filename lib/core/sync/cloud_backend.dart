import '../sessions/session.dart';

/// Where sessions are backed up. The app ships with [NoCloudBackend]; a
/// Firebase implementation plugs in here without changes elsewhere.
///
/// Only session records sync (scores, measurements, feedback and notes).
/// Video clips and pose data stay on the phone.
abstract interface class CloudBackend {
  /// False until a cloud project has been connected to this build.
  bool get isConfigured;

  /// Creates or replaces these sessions in the cloud. Deleted sessions are
  /// sent with `deleted` set so that other devices remove them too.
  Future<void> push(String userId, List<Session> sessions);

  /// Sessions changed in the cloud after [since] (all of them when null).
  Future<List<Session>> pull(String userId, {DateTime? since});
}

/// The backend used until a cloud project is connected.
class NoCloudBackend implements CloudBackend {
  const NoCloudBackend();

  @override
  bool get isConfigured => false;

  @override
  Future<void> push(String userId, List<Session> sessions) async {
    throw const SyncException('Cloud sync is not set up in this version.');
  }

  @override
  Future<List<Session>> pull(String userId, {DateTime? since}) async {
    throw const SyncException('Cloud sync is not set up in this version.');
  }
}

/// A sync could not finish. [message] is written for the player.
class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => 'SyncException: $message';
}
