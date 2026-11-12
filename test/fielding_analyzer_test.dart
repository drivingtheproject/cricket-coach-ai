import 'package:cricket_coach_ai/core/analysis/analyzers.dart';
import 'package:cricket_coach_ai/core/analysis/body.dart';
import 'package:cricket_coach_ai/core/analysis/fielding_analyzer.dart';
import 'package:cricket_coach_ai/core/analysis/filming_guide.dart';
import 'package:cricket_coach_ai/core/analysis/hands.dart';
import 'package:cricket_coach_ai/core/analysis/metric.dart';
import 'package:cricket_coach_ai/core/analysis/technique_analysis.dart';
import 'package:cricket_coach_ai/core/analysis_exception.dart';
import 'package:cricket_coach_ai/core/pose/pose_frame.dart';
import 'package:cricket_coach_ai/core/sessions/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_clips.dart';

Pt pt((double, double) p) => Pt(p.$1, p.$2);

void main() {
  const analyzer = FieldingAnalyzer();

  TechniqueAnalysis analyse(List<PoseFrame> frames) => analyzer.analyze(
        frames,
        handedness: Handedness.right,
        aspectRatio: 1,
      );

  MetricResult metric(TechniqueAnalysis analysis, MetricSpec spec) =>
      analysis.metrics.singleWhere((m) => m.id == spec.id);

  final scale = BodyTrack(catchingClip(), 1).scale!;

  test('is registered for fielding and reports every spec', () {
    expect(defaultAnalyzers()[Discipline.fielding], isA<FieldingAnalyzer>());
    expect(
      analyse(catchingClip()).metrics.map((m) => m.id),
      analyzer.specs.map((s) => s.id),
    );
    expect(FilmingGuide.of(Discipline.fielding).handQuestion, isNull);
  });

  group('hand helpers', () {
    final track = BodyTrack(catchingClip(), 1);

    test('findTake finds where the hands close after reaching', () {
      expect(findTake(track, notFound: 'none'), catchFrame);
    });

    test('wrist gap narrows from ready to the catch', () {
      final gaps = wristGaps(track);
      expect(gaps[0], closeTo(0.20 / scale * 100, 1e-6));
      expect(gaps[catchFrame], closeTo(catchHandGap / scale * 100, 1e-6));
    });

    test('hand travel adds up the path between two frames', () {
      expect(handTravel(track, 0, 5), closeTo(0, 1e-9));
      expect(
        handTravel(track, catchFrame, 18),
        closeTo(catchGive / scale * 100, 1e-6),
      );
      expect(handTravel(track, 28, 500), closeTo(0, 1e-9));
    });

    test('helpers return null when the landmarks are hidden', () {
      final hidden = BodyTrack(
        [
          for (var i = 0; i < 3; i++)
            frameOf(timeOf(i), const {PoseLandmarkIndex.nose: (0.5, 0.2)}),
        ],
        1,
      );
      final frame = hidden.frames.first;
      expect(kneeBend(frame), isNull);
      expect(elbowBend(frame), isNull);
      expect(wristGaps(hidden).every((gap) => gap.isNaN), isTrue);
    });
  });

  group('phases', () {
    test('ready, catch and give are in order around the catch', () {
      final phases = analyse(catchingClip()).phases;

      expect(phases.map((p) => p.label), ['Ready', 'Catch', 'Give']);
      expect(phases[1].timeMs, timeOf(catchFrame));
      expect(phases[0].timeMs, lessThan(phases[1].timeMs));
      expect(phases[2].timeMs, greaterThan(phases[1].timeMs));
    });
  });

  group('metrics', () {
    final analysis = analyse(catchingClip());

    test('hands are measured together at the catch', () {
      final gap = metric(analysis, FieldingAnalyzer.handsTogether);
      expect(gap.value, closeTo(catchHandGap / scale * 100, 0.1));
      expect(gap.status, MetricStatus.good);
    });

    test('stance width is the gap between the feet', () {
      final base = metric(analysis, FieldingAnalyzer.base);
      expect(base.value, closeTo(catchStanceWidth / scale * 100, 0.1));
    });

    test('knee bend matches the pose that was drawn', () {
      final expected =
          angleBetween(pt(catchHip), pt(catchKnee), pt(catchAnkle));
      expect(
        metric(analysis, FieldingAnalyzer.kneeFlex).value,
        closeTo(expected, 0.1),
      );
    });

    test('head is in line with the hands', () {
      final head = metric(analysis, FieldingAnalyzer.headLine);
      expect(head.value, closeTo(0, 0.1));
      expect(head.score, 100);
    });

    test('give is how far the hands ride back after the catch', () {
      // 300 ms is 4 or 5 frames of the 4-frame give, so nearly all of it.
      final give = metric(analysis, FieldingAnalyzer.give);
      expect(give.value, closeTo(catchGive / scale * 100, 0.5));
      expect(give.status, MetricStatus.good);
    });

    test('a still head scores full marks', () {
      expect(metric(analysis, FieldingAnalyzer.headSteady).score, 100);
    });
  });

  group('clips that cannot be analysed', () {
    test('hands that never move are not a catch', () {
      expect(
        () => analyse(catchingClip(handsApart: true)),
        throwsA(
          isA<AnalysisException>().having(
            (e) => e.message,
            'message',
            contains('could not find a catch'),
          ),
        ),
      );
    });

    test('hands that move but stay apart are not a catch', () {
      // The batting clip's hands are side by side but the bowling clip's
      // are far apart while the arm swings.
      expect(
        () => analyse(bowlingClip()),
        throwsA(isA<AnalysisException>()),
      );
    });

    test('a clip without a full body is rejected', () {
      final headOnly = [
        for (var i = 0; i < 10; i++)
          frameOf(timeOf(i), const {PoseLandmarkIndex.nose: (0.5, 0.2)}),
      ];
      expect(
        () => analyse(headOnly),
        throwsA(
          isA<AnalysisException>()
              .having((e) => e.message, 'message', contains('whole body')),
        ),
      );
    });
  });
}
