import 'package:cricket_coach_ai/core/analysis/analyzers.dart';
import 'package:cricket_coach_ai/core/analysis/body.dart';
import 'package:cricket_coach_ai/core/analysis/filming_guide.dart';
import 'package:cricket_coach_ai/core/analysis/keeping_analyzer.dart';
import 'package:cricket_coach_ai/core/analysis/metric.dart';
import 'package:cricket_coach_ai/core/analysis/technique_analysis.dart';
import 'package:cricket_coach_ai/core/analysis_exception.dart';
import 'package:cricket_coach_ai/core/pose/pose_frame.dart';
import 'package:cricket_coach_ai/core/sessions/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_clips.dart';

Pt pt((double, double) p) => Pt(p.$1, p.$2);

void main() {
  const analyzer = KeepingAnalyzer();

  TechniqueAnalysis analyse(List<PoseFrame> frames) => analyzer.analyze(
        frames,
        handedness: Handedness.right,
        aspectRatio: 1,
      );

  MetricResult metric(TechniqueAnalysis analysis, MetricSpec spec) =>
      analysis.metrics.singleWhere((m) => m.id == spec.id);

  final scale = BodyTrack(keepingClip(), 1).scale!;

  test('is registered for wicketkeeping and reports every spec', () {
    expect(
      defaultAnalyzers()[Discipline.wicketkeeping],
      isA<KeepingAnalyzer>(),
    );
    expect(
      analyse(keepingClip()).metrics.map((m) => m.id),
      analyzer.specs.map((s) => s.id),
    );
    expect(FilmingGuide.of(Discipline.wicketkeeping).handQuestion, isNull);
  });

  test('every discipline has an analyzer', () {
    expect(defaultAnalyzers().keys, Discipline.values);
  });

  group('phases', () {
    test('set, take and give are found in order', () {
      final phases = analyse(keepingClip()).phases;

      expect(phases.map((p) => p.label), ['Set', 'Take', 'Give']);
      expect(phases[1].timeMs, timeOf(keepingTakeFrame));
      // The crouch is held from the start, so set is found before the rise.
      expect(phases[0].timeMs, lessThanOrEqualTo(timeOf(12)));
      expect(phases[2].timeMs, greaterThan(phases[1].timeMs));
    });
  });

  group('metrics', () {
    final analysis = analyse(keepingClip());

    test('crouch depth matches the pose that was drawn', () {
      final expected = angleBetween(
        pt(keepingSetHip),
        pt(keepingKnee),
        pt(keepingAnkle),
      );

      final crouch = metric(analysis, KeepingAnalyzer.crouch);

      expect(crouch.value, closeTo(expected, 0.1));
      expect(crouch.status, MetricStatus.good);
    });

    test('stance width is the gap between the feet', () {
      expect(
        metric(analysis, KeepingAnalyzer.stance).value,
        closeTo(keepingStanceWidth / scale * 100, 0.1),
      );
    });

    test('rise is how far the head comes up before the take', () {
      expect(
        metric(analysis, KeepingAnalyzer.rise).value,
        closeTo(keepingHeadRise / scale * 100, 0.1),
      );
    });

    test('gloves are together and under the head at the take', () {
      final gap = metric(analysis, KeepingAnalyzer.glovesTogether);
      expect(gap.value, closeTo(keepingGloveGap / scale * 100, 0.1));
      expect(gap.status, MetricStatus.good);
      expect(metric(analysis, KeepingAnalyzer.headLine).value, closeTo(0, 0.1));
    });

    test('give is measured after the take', () {
      // The gloves travel 0.08 over the four frames after the take.
      final give = metric(analysis, KeepingAnalyzer.give);
      expect(give.value, closeTo(0.08 / scale * 100, 0.5));
    });

    test('a keeper who never crouches is told to get lower', () {
      final tall = analyse(keepingClip(standsTall: true));

      final crouch = metric(tall, KeepingAnalyzer.crouch);
      expect(crouch.status, MetricStatus.high);
      expect(crouch.note, contains('get lower'));
      expect(metric(tall, KeepingAnalyzer.rise).value, closeTo(0, 0.1));
    });
  });

  group('clips that cannot be analysed', () {
    test('gloves that never close are not a take', () {
      expect(
        () => analyse(catchingClip(wide: true)),
        throwsA(
          isA<AnalysisException>().having(
            (e) => e.message,
            'message',
            contains('could not find a take'),
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
          isA<AnalysisException>()
              .having((e) => e.message, 'message', contains('whole body')),
        ),
      );
    });
  });
}
