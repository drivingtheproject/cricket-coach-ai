import 'package:cricket_coach_ai/core/analysis/metric.dart';
import 'package:cricket_coach_ai/core/analysis/technique_analysis.dart';
import 'package:cricket_coach_ai/core/sessions/session.dart';
import 'package:flutter_test/flutter_test.dart';

const spec = MetricSpec(
  id: 'knee',
  label: 'Knee',
  unit: '°',
  idealMin: 100,
  idealMax: 140,
  tolerance: 40,
  scaleMin: 60,
  scaleMax: 180,
  good: 'good note',
  low: 'low note',
  high: 'high note',
);

void main() {
  group('rangeScore', () {
    test('is 100 anywhere inside the range, including its ends', () {
      expect(rangeScore(100, 100, 140, 40), 100);
      expect(rangeScore(120, 100, 140, 40), 100);
      expect(rangeScore(140, 100, 140, 40), 100);
    });

    test('falls in a straight line outside the range', () {
      expect(rangeScore(90, 100, 140, 40), closeTo(75, 1e-9));
      expect(rangeScore(160, 100, 140, 40), closeTo(50, 1e-9));
    });

    test('is 0 at and beyond the tolerance', () {
      expect(rangeScore(60, 100, 140, 40), 0);
      expect(rangeScore(300, 100, 140, 40), 0);
    });

    test('a zero tolerance scores 0 for anything outside', () {
      expect(rangeScore(141, 100, 140, 0), 0);
    });
  });

  group('MetricSpec.evaluate', () {
    test('picks the status and note for the value', () {
      expect(spec.evaluate(120).status, MetricStatus.good);
      expect(spec.evaluate(120).note, 'good note');
      expect(spec.evaluate(80).status, MetricStatus.low);
      expect(spec.evaluate(80).note, 'low note');
      expect(spec.evaluate(170).status, MetricStatus.high);
      expect(spec.evaluate(170).note, 'high note');
    });

    test('formats the value and guide range', () {
      final result = spec.evaluate(123.6);
      expect(result.valueText, '124°');
      expect(result.guideText, '100-140°');
    });
  });

  group('TechniqueAnalysis', () {
    final analysis = TechniqueAnalysis(
      discipline: Discipline.batting,
      handedness: Handedness.left,
      metrics: [spec.evaluate(120), spec.evaluate(160), spec.evaluate(70)],
      phases: const [PhaseMarker('Backlift', 400), PhaseMarker('Impact', 900)],
    );

    test('score is the mean of the metric scores', () {
      // 100, 50 and 25.
      expect(analysis.score, closeTo(175 / 3, 1e-9));
    });

    test('an analysis without metrics scores 0', () {
      const empty = TechniqueAnalysis(
        discipline: Discipline.batting,
        handedness: Handedness.right,
        metrics: [],
        phases: [],
      );
      expect(empty.score, 0);
    });

    test('splits strengths from weaknesses, worst first', () {
      expect(analysis.strengths.map((m) => m.value), [120]);
      expect(analysis.weaknesses.map((m) => m.value), [70, 160]);
    });

    test('survives encoding and decoding', () {
      final decoded = TechniqueAnalysis.decode(analysis.encode());

      expect(decoded.discipline, Discipline.batting);
      expect(decoded.handedness, Handedness.left);
      expect(decoded.metrics, hasLength(3));
      expect(decoded.metrics[1].id, 'knee');
      expect(decoded.metrics[1].value, 160);
      expect(decoded.metrics[1].status, MetricStatus.high);
      expect(decoded.metrics[1].score, closeTo(50, 0.05));
      expect(decoded.metrics[1].note, 'high note');
      expect(decoded.phases.map((p) => (p.label, p.timeMs)), [
        ('Backlift', 400),
        ('Impact', 900),
      ]);
    });
  });
}
