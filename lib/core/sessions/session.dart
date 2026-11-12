enum Discipline {
  batting('Batting'),
  bowling('Bowling'),
  fielding('Fielding');

  const Discipline(this.label);
  final String label;
}

enum Handedness {
  right('Right-handed'),
  left('Left-handed');

  const Handedness(this.label);
  final String label;
}

/// Whether a row still has local changes the cloud has not seen.
enum SyncState { pending, synced }

/// One analysed clip, as stored in the `sessions` table.
class Session {
  const Session({
    required this.id,
    required this.userId,
    required this.title,
    required this.discipline,
    required this.handedness,
    required this.createdAt,
    required this.updatedAt,
    this.videoPath,
    this.durationMs = 0,
    this.analysisJson,
    this.feedbackJson,
    this.coachProvider,
    this.notes = '',
    this.score,
    this.syncState = SyncState.pending,
    this.deleted = false,
  });

  factory Session.fromRow(Map<String, Object?> row) => Session(
        id: row['id']! as String,
        userId: row['user_id']! as String,
        title: row['title']! as String,
        discipline: Discipline.values.byName(row['discipline']! as String),
        handedness: Handedness.values.byName(row['handedness']! as String),
        videoPath: row['video_path'] as String?,
        durationMs: row['duration_ms']! as int,
        analysisJson: row['analysis_json'] as String?,
        feedbackJson: row['feedback_json'] as String?,
        coachProvider: row['coach_provider'] as String?,
        notes: row['notes']! as String,
        score: (row['score'] as num?)?.toDouble(),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
        syncState: SyncState.values.byName(row['sync_state']! as String),
        deleted: (row['deleted']! as int) == 1,
      );

  final String id;
  final String userId;
  final String title;
  final Discipline discipline;
  final Handedness handedness;

  /// Path of the clip relative to the app's documents folder.
  final String? videoPath;
  final int durationMs;

  /// Encoded analysis result (metrics and phases).
  final String? analysisJson;

  /// Encoded coach feedback.
  final String? feedbackJson;

  /// Which coach wrote the feedback.
  final String? coachProvider;
  final String notes;

  /// Overall technique score, 0-100.
  final double? score;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final bool deleted;

  Session copyWith({
    String? title,
    String? videoPath,
    int? durationMs,
    String? analysisJson,
    String? feedbackJson,
    String? coachProvider,
    String? notes,
    double? score,
    DateTime? updatedAt,
    SyncState? syncState,
    bool? deleted,
  }) {
    return Session(
      id: id,
      userId: userId,
      title: title ?? this.title,
      discipline: discipline,
      handedness: handedness,
      videoPath: videoPath ?? this.videoPath,
      durationMs: durationMs ?? this.durationMs,
      analysisJson: analysisJson ?? this.analysisJson,
      feedbackJson: feedbackJson ?? this.feedbackJson,
      coachProvider: coachProvider ?? this.coachProvider,
      notes: notes ?? this.notes,
      score: score ?? this.score,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'discipline': discipline.name,
        'handedness': handedness.name,
        'video_path': videoPath,
        'duration_ms': durationMs,
        'analysis_json': analysisJson,
        'feedback_json': feedbackJson,
        'coach_provider': coachProvider,
        'notes': notes,
        'score': score,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'sync_state': syncState.name,
        'deleted': deleted ? 1 : 0,
      };
}
