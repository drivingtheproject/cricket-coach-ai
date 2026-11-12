import '../analysis/metric.dart';
import '../analysis/technique_analysis.dart';
import '../coach/drills.dart';
import '../sessions/session.dart';

/// One scored session on the progress chart.
class ScorePoint {
  const ScorePoint(this.date, this.score);

  final DateTime date;
  final double score;
}

/// A measurement that keeps falling outside its guide range.
class FocusArea {
  const FocusArea({
    required this.label,
    required this.note,
    required this.count,
    this.drill,
  });

  final String label;
  final String note;

  /// In how many of the recent sessions it was out of range.
  final int count;
  final Drill? drill;
}

/// A player's progress in one discipline, worked out from their sessions.
class ProgressSummary {
  const ProgressSummary({
    required this.discipline,
    required this.points,
    required this.focusAreas,
    required this.recentCount,
  });

  /// Builds the summary from [sessions] in any order. Sessions of other
  /// disciplines, deleted sessions and sessions without a score are ignored.
  /// Focus areas look at the newest [recent] sessions.
  factory ProgressSummary.from(
    List<Session> sessions,
    Discipline discipline, {
    int recent = 5,
  }) {
    final scored = sessions
        .where(
          (s) => s.discipline == discipline && !s.deleted && s.score != null,
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final latest =
        scored.length <= recent ? scored : scored.sublist(scored.length - recent);

    // Newest session first, so the note and drill shown are the latest ones.
    final areas = <String, FocusArea>{};
    for (final session in latest.reversed) {
      final encoded = session.analysisJson;
      if (encoded == null) continue;
      final TechniqueAnalysis analysis;
      try {
        analysis = TechniqueAnalysis.decode(encoded);
      } on Object {
        continue; // An unreadable analysis should not break the chart.
      }
      for (final metric in analysis.metrics) {
        if (metric.status == MetricStatus.good) continue;
        final existing = areas[metric.id];
        areas[metric.id] = FocusArea(
          label: metric.label,
          note: existing?.note ?? metric.note,
          drill: existing?.drill ?? drillFor(metric),
          count: (existing?.count ?? 0) + 1,
        );
      }
    }
    final focus = areas.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return ProgressSummary(
      discipline: discipline,
      points: [for (final s in scored) ScorePoint(s.createdAt, s.score!)],
      focusAreas: focus.take(3).toList(),
      recentCount: latest.length,
    );
  }

  final Discipline discipline;

  /// Scored sessions, oldest first.
  final List<ScorePoint> points;

  /// Up to three measurements most often out of range recently.
  final List<FocusArea> focusAreas;

  /// How many sessions the focus areas were drawn from.
  final int recentCount;

  bool get isEmpty => points.isEmpty;

  double? get latest => isEmpty ? null : points.last.score;

  double? get best => isEmpty
      ? null
      : points.map((p) => p.score).reduce((a, b) => a > b ? a : b);

  double? get average => isEmpty
      ? null
      : points.fold<double>(0, (sum, p) => sum + p.score) / points.length;

  /// Latest score minus the first one; null with fewer than two sessions.
  double? get change =>
      points.length < 2 ? null : points.last.score - points.first.score;
}

/// Disciplines that have at least one scored session, in enum order.
List<Discipline> disciplinesWithScores(List<Session> sessions) => [
      for (final discipline in Discipline.values)
        if (sessions.any(
          (s) => s.discipline == discipline && !s.deleted && s.score != null,
        ))
          discipline,
    ];
