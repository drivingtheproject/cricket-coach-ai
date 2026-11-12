import 'package:cricket_coach_ai/core/analysis/analyzers.dart';
import 'package:cricket_coach_ai/core/analysis/batting_analyzer.dart';
import 'package:cricket_coach_ai/core/analysis/body.dart';
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
  const analyzer = BattingAnalyzer();

  TechniqueAnalysis analyse(
    List<PoseFrame> frames, {
    Handedness hand = Handedness.right,
  }) =>
      analyzer.analyze(frames, handedness: hand, aspectRatio: 1);

  MetricResult metric(TechniqueAnalysis analysis, MetricSpec spec) =>
      analysis.metrics.singleWhere((m) => m.id == spec.id);

  test('is registered for batting', () {
    expect(defaultAnalyzers()[Discipline.batting], isA<BattingAnalyzer>());
  });

  group('phases', () {
    test('finds the moments of the shot in order', () {
      final phases = analyse(battingClip()).phases;

      expect(phases.map((p) => p.label), [
        'Stance',
        'Backlift',
        'Impact',
        'Finish',
      ]);
      final times = phases.map((p) => p.timeMs).toList();
      expect(times, [...times]..sort());
    });

    test('backlift is where the hands are highest before the swing', () {
      final backlift = analyse(battingClip())
          .phases
          .singleWhere((p) => p.label == 'Backlift');
      expect(
        backlift.timeMs,
        inInclusiveRange(timeOf(battingTopFrame - 1), timeOf(battingTopFrame)),
      );
    });

    test('impact falls inside the downswing', () {
      final impact =
          analyse(battingClip()).phases.singleWhere((p) => p.label == 'Impact');
      expect(
        impact.timeMs,
        inInclusiveRange(timeOf(battingSwingStart), timeOf(battingSwingEnd)),
      );
    });
  });

  group('metrics', () {
    test('measures every batting metric', () {
      expect(analyse(battingClip()).metrics.map((m) => m.id), [
        'front_knee',
        'front_elbow',
        'head_over_front_foot',
        'stride',
        'backlift',
        'head_level',
        'finish_balance',
      ]);
    });

    test('front knee angle matches the pose that was drawn', () {
      final expected = angleBetween(
        pt(battingFrontHip),
        pt(battingFrontKnee),
        pt(battingFrontAnkle),
      );

      final knee = metric(analyse(battingClip()), BattingAnalyzer.frontKnee);

      expect(knee.value, closeTo(expected, 0.5));
      expect(knee.unit, '°');
    });

    test('stride is the gap between the feet in body lengths', () {
      final track = BodyTrack(battingClip(), 1);
      final expected =
          (battingFrontAnkle.$1 - battingBackAnkle.$1) / track.scale! * 100;

      final stride = metric(analyse(battingClip()), BattingAnalyzer.stride);

      expect(stride.value, closeTo(expected, 0.5));
      expect(stride.status, MetricStatus.good);
    });

    test('backlift height is measured at the top of the backlift', () {
      final track = BodyTrack(battingClip(), 1);
      // Hips are at y 0.56 and the hands reach y 0.28.
      final expected = (0.56 - 0.28) / track.scale! * 100;

      final backlift = metric(analyse(battingClip()), BattingAnalyzer.backlift);

      expect(backlift.value, closeTo(expected, 3));
    });

    test('a steady head scores full marks for head movement', () {
      final head = metric(analyse(battingClip()), BattingAnalyzer.headLevel);
      expect(head.status, MetricStatus.good);
      expect(head.score, 100);
    });

    test('a left-hander is measured on the mirrored side', () {
      final right = analyse(battingClip());
      final left = analyse(
        battingClip(leftHanded: true),
        hand: Handedness.left,
      );

      expect(left.handedness, Handedness.left);
      for (final spec in [BattingAnalyzer.frontKnee, BattingAnalyzer.stride]) {
        expect(
          metric(left, spec).value,
          closeTo(metric(right, spec).value, 1e-6),
        );
      }
    });

    test('score is between 0 and 100', () {
      expect(analyse(battingClip()).score, inInclusiveRange(0, 100));
    });
  });

  group('clips that cannot be analysed', () {
    test('a clip with no swing is rejected', () {
      final still = [
        for (var i = 0; i < 20; i++)
          PoseFrame(timestampMs: timeOf(i), landmarks: standingPose()),
      ];

      expect(
        () => analyse(still),
        throwsA(
          isA<AnalysisException>().having(
            (e) => e.message,
            'message',
            contains('could not find a shot'),
          ),
        ),
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
          isA<AnalysisException>().having(
            (e) => e.message,
            'message',
            contains('whole body'),
          ),
        ),
      );
    });

    test('frames without a detection are tolerated', () {
      final frames = battingClip();
      frames[3] = PoseFrame(timestampMs: timeOf(3), landmarks: const []);
      frames[25] = PoseFrame(timestampMs: timeOf(25), landmarks: const []);

      expect(analyse(frames).metrics, isNotEmpty);
    });
  });
}
