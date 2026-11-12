import 'package:cricket_coach_ai/core/analysis/analyzers.dart';
import 'package:cricket_coach_ai/core/analysis/body.dart';
import 'package:cricket_coach_ai/core/analysis/bowling_analyzer.dart';
import 'package:cricket_coach_ai/core/analysis/filming_guide.dart';
import 'package:cricket_coach_ai/core/analysis/metric.dart';
import 'package:cricket_coach_ai/core/analysis/technique_analysis.dart';
import 'package:cricket_coach_ai/core/analysis_exception.dart';
import 'package:cricket_coach_ai/core/pose/pose_frame.dart';
import 'package:cricket_coach_ai/core/sessions/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_pose.dart';
import 'support/synthetic_clips.dart';

Pt pt((double, double) p) => Pt(p.$1, p.$2);

void main() {
  const analyzer = BowlingAnalyzer();

  TechniqueAnalysis analyse(
    List<PoseFrame> frames, {
    Handedness hand = Handedness.right,
  }) =>
      analyzer.analyze(frames, handedness: hand, aspectRatio: 1);

  MetricResult metric(TechniqueAnalysis analysis, MetricSpec spec) =>
      analysis.metrics.singleWhere((m) => m.id == spec.id);

  test('is registered for bowling and reports every spec', () {
    expect(defaultAnalyzers()[Discipline.bowling], isA<BowlingAnalyzer>());
    expect(
      analyse(bowlingClip()).metrics.map((m) => m.id),
      analyzer.specs.map((s) => s.id),
    );
  });

  test('every discipline has filming tips', () {
    for (final discipline in Discipline.values) {
      final guide = FilmingGuide.of(discipline);
      expect(guide.intro, isNotEmpty);
      expect(guide.tips, isNotEmpty);
    }
    expect(FilmingGuide.of(Discipline.bowling).handQuestion, contains('bowl'));
  });

  group('phases', () {
    test('release is where the bowling hand is highest', () {
      final release =
          analyse(bowlingClip()).phases.singleWhere((p) => p.label == 'Release');
      expect(release.timeMs, timeOf(bowlingReleaseFrame));
    });

    test('landing, release and follow-through are in order', () {
      final phases = analyse(bowlingClip()).phases;
      expect(phases.map((p) => p.label), [
        'Front foot lands',
        'Release',
        'Follow-through',
      ]);
      final times = phases.map((p) => p.timeMs).toList();
      expect(times, [...times]..sort());
      expect(times.first, greaterThanOrEqualTo(timeOf(bowlingLandFrame)));
    });
  });

  group('metrics', () {
    test('a straight arm measures 180 degrees and scores full marks', () {
      final arm = metric(analyse(bowlingClip()), BowlingAnalyzer.armStraightness);
      expect(arm.value, closeTo(180, 0.5));
      expect(arm.score, 100);
    });

    test('a bent arm is measured as bent', () {
      final arm = metric(
        analyse(bowlingClip(elbowBend: 0.06)),
        BowlingAnalyzer.armStraightness,
      );
      expect(arm.value, lessThan(140));
      expect(arm.status, MetricStatus.low);
    });

    test('release height is the arm length above the shoulder', () {
      final track = BodyTrack(bowlingClip(), 1);
      final expected = bowlingArmLength / track.scale! * 100;

      final height =
          metric(analyse(bowlingClip()), BowlingAnalyzer.releaseHeight);

      expect(height.value, closeTo(expected, 0.5));
      expect(height.status, MetricStatus.good);
    });

    test('front knee angle matches the pose that was drawn', () {
      final expected = angleBetween(
        pt(bowlingFrontHip),
        pt(bowlingFrontKnee),
        pt(bowlingFrontAnkle),
      );

      final knee = metric(analyse(bowlingClip()), BowlingAnalyzer.frontKnee);

      expect(knee.value, closeTo(expected, 0.5));
      expect(knee.status, MetricStatus.good);
    });

    test('stride is measured once the front foot has landed', () {
      final track = BodyTrack(bowlingClip(), 1);
      final expected =
          (bowlingFrontAnkle.$1 - bowlingBackAnkle.$1) / track.scale! * 100;

      final stride = metric(analyse(bowlingClip()), BowlingAnalyzer.stride);

      expect(stride.value, closeTo(expected, 0.5));
    });

    test('an upright trunk is reported as low lean', () {
      final lean = metric(analyse(bowlingClip()), BowlingAnalyzer.trunkLean);
      expect(lean.value, lessThan(10));
      expect(lean.status, MetricStatus.low);
    });

    test('a left-arm bowler is measured on the mirrored side', () {
      final right = analyse(bowlingClip());
      final left = analyse(bowlingClip(leftArm: true), hand: Handedness.left);

      for (final spec in analyzer.specs) {
        expect(
          metric(left, spec).value,
          closeTo(metric(right, spec).value, 1e-6),
          reason: spec.id,
        );
      }
    });
  });

  group('clips that cannot be analysed', () {
    test('a clip where the arm never goes above the shoulder', () {
      // The first 12 frames of the batting clip: hands stay below the chest.
      expect(
        () => analyse(battingClip(frames: 12)),
        throwsA(
          isA<AnalysisException>().having(
            (e) => e.message,
            'message',
            contains('could not find a delivery'),
          ),
        ),
      );
    });

    test('a raised arm that is not moving is not a delivery', () {
      final held = [
        for (var i = 0; i < 20; i++)
          PoseFrame(
            timestampMs: timeOf(i),
            landmarks: bowlingClip()[bowlingReleaseFrame].landmarks,
          ),
      ];
      expect(() => analyse(held), throwsA(isA<AnalysisException>()));
    });

    test('a clip without a full body is rejected', () {
      final still = [
        for (var i = 0; i < 10; i++)
          frameOf(timeOf(i), const {PoseLandmarkIndex.nose: (0.5, 0.2)}),
      ];
      expect(
        () => analyse(still),
        throwsA(
          isA<AnalysisException>()
              .having((e) => e.message, 'message', contains('whole body')),
        ),
      );
      expect(standingPose(), hasLength(PoseLandmarkIndex.count));
    });
  });
}
