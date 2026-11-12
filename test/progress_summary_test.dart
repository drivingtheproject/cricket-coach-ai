import 'package:cricket_coach_ai/core/analysis/batting_analyzer.dart';
import 'package:cricket_coach_ai/core/analysis/metric.dart';
import 'package:cricket_coach_ai/core/analysis/technique_analysis.dart';
import 'package:cricket_coach_ai/core/progress/progress_summary.dart';
import 'package:cricket_coach_ai/core/sessions/session.dart';
import 'package:flutter_test/flutter_test.dart';

Session scored(
  int day,
  double? score, {
  Discipline discipline = Discipline.batting,
  List<MetricResult> metrics = const [],
  bool deleted = false,
  String? analysisJson,
}) {
  final date = DateTime(2026, 11, day);
  return Session(
    id: 's$day-${discipline.name}',
    userId: 'user-1',
    title: 'Session',
    discipline: discipline,
    handedness: Handedness.right,
    createdAt: date,
    updatedAt: date,
    score: score,
    deleted: deleted,
    analysisJson: analysisJson ??
        TechniqueAnalysis(
          discipline: discipline,
          handedness: Handedness.right,
          metrics: metrics,
          phases: const [],
        ).encode(),
  );
}

void main() {
  final shortStride = BattingAnalyzer.stride.evaluate(10);
  final goodStride = BattingAnalyzer.stride.evaluate(45);
  final headAway = BattingAnalyzer.headOverFoot.evaluate(35);
  final straightLeg = BattingAnalyzer.frontKnee.evaluate(175);

  group('ProgressSummary', () {
    test('orders points by date and works out the numbers', () {
      final summary = ProgressSummary.from(
        [scored(3, 70), scored(1, 50), scored(2, 80)],
        Discipline.batting,
      );

      expect(summary.points.map((p) => p.score), [50, 80, 70]);
      expect(summary.latest, 70);
      expect(summary.best, 80);
      expect(summary.average, closeTo(200 / 3, 1e-9));
      expect(summary.change, 20);
      expect(summary.isEmpty, isFalse);
    });

    test('ignores other disciplines, deleted and unscored sessions', () {
      final summary = ProgressSummary.from(
        [
          scored(1, 50),
          scored(2, 90, discipline: Discipline.bowling),
          scored(3, 95, deleted: true),
          scored(4, null),
        ],
        Discipline.batting,
      );

      expect(summary.points.map((p) => p.score), [50]);
    });

    test('is empty with no sessions and has no change with one', () {
      final empty = ProgressSummary.from(const [], Discipline.batting);
      expect(empty.isEmpty, isTrue);
      expect(empty.latest, isNull);
      expect(empty.best, isNull);
      expect(empty.average, isNull);
      expect(empty.change, isNull);

      final one = ProgressSummary.from([scored(1, 60)], Discipline.batting);
      expect(one.change, isNull);
      expect(one.latest, 60);
    });

    test('focus areas are the measurements most often out of range', () {
      final summary = ProgressSummary.from(
        [
          scored(1, 50, metrics: [shortStride, headAway, straightLeg]),
          scored(2, 60, metrics: [shortStride, headAway]),
          scored(3, 70, metrics: [shortStride, goodStride]),
        ],
        Discipline.batting,
      );

      expect(summary.recentCount, 3);
      expect(summary.focusAreas.map((a) => (a.label, a.count)), [
        (BattingAnalyzer.stride.label, 3),
        (BattingAnalyzer.headOverFoot.label, 2),
        (BattingAnalyzer.frontKnee.label, 1),
      ]);
      expect(summary.focusAreas.first.note, BattingAnalyzer.stride.low);
      expect(summary.focusAreas.first.drill, isNotNull);
    });

    test('focus areas only look at the most recent sessions', () {
      final summary = ProgressSummary.from(
        [
          scored(1, 40, metrics: [headAway]),
          scored(2, 50, metrics: [shortStride]),
          scored(3, 60, metrics: [shortStride]),
        ],
        Discipline.batting,
        recent: 2,
      );

      expect(summary.recentCount, 2);
      expect(summary.focusAreas.single.label, BattingAnalyzer.stride.label);
      expect(summary.points, hasLength(3));
    });

    test('no focus areas when everything is in range', () {
      final summary = ProgressSummary.from(
        [scored(1, 100, metrics: [goodStride])],
        Discipline.batting,
      );
      expect(summary.focusAreas, isEmpty);
    });

    test('an unreadable analysis is skipped, not fatal', () {
      final summary = ProgressSummary.from(
        [scored(1, 50, analysisJson: 'not json')],
        Discipline.batting,
      );
      expect(summary.points, hasLength(1));
      expect(summary.focusAreas, isEmpty);
    });
  });

  test('disciplinesWithScores lists only disciplines that can be charted', () {
    expect(disciplinesWithScores(const []), isEmpty);
    expect(
      disciplinesWithScores([
        scored(1, 50, discipline: Discipline.bowling),
        scored(2, null),
        scored(3, 70, deleted: true),
      ]),
      [Discipline.bowling],
    );
  });
}
