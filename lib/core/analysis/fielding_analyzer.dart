import '../analysis_exception.dart';
import '../pose/pose_frame.dart';
import '../sessions/session.dart';
import 'body.dart';
import 'hands.dart';
import 'metric.dart';
import 'technique_analysis.dart';
import 'technique_analyzer.dart';

/// Measures a two-handed catch filmed from in front or from the side.
///
/// The catch is the moment the hands close after reaching for the ball. The
/// ball itself is not tracked, so whether it was held is not judged.
class FieldingAnalyzer implements TechniqueAnalyzer {
  const FieldingAnalyzer();

  static const handsTogether = MetricSpec(
    id: 'field_hands_together',
    label: 'Gap between hands at the catch',
    unit: '%',
    idealMin: 0,
    idealMax: 12,
    tolerance: 15,
    scaleMin: 0,
    scaleMax: 40,
    good: 'Hands are together, making one big target.',
    low: 'Hands are together, making one big target.',
    high: 'Hands are apart at the catch; bring them together to make a cup.',
  );

  static const kneeFlex = MetricSpec(
    id: 'field_knees',
    label: 'Knee bend at the catch',
    unit: '°',
    idealMin: 110,
    idealMax: 160,
    tolerance: 30,
    scaleMin: 60,
    scaleMax: 180,
    good: 'Knees are bent, so you can adjust to the ball.',
    low: 'You are squatting very low, which makes it hard to move.',
    high: 'Legs are straight; bend your knees so you can adjust late.',
  );

  static const base = MetricSpec(
    id: 'field_base',
    label: 'Width of stance',
    unit: '%',
    idealMin: 22,
    idealMax: 50,
    tolerance: 20,
    scaleMin: 0,
    scaleMax: 80,
    good: 'Feet are about shoulder-width apart, giving a steady base.',
    low: 'Feet are close together, which makes you easy to unbalance.',
    high: 'Feet are very wide apart, which slows your first step.',
  );

  static const headLine = MetricSpec(
    id: 'field_head_line',
    label: 'Head from hands at the catch',
    unit: '%',
    idealMin: 0,
    idealMax: 15,
    tolerance: 20,
    scaleMin: 0,
    scaleMax: 50,
    good: 'Head is in line with your hands, so your eyes are behind the ball.',
    low: 'Head is in line with your hands, so your eyes are behind the ball.',
    high: 'You are catching away from your head; move your feet to get '
        'behind the ball.',
  );

  static const softElbows = MetricSpec(
    id: 'field_elbows',
    label: 'Elbow bend at the catch',
    unit: '°',
    idealMin: 80,
    idealMax: 150,
    tolerance: 30,
    scaleMin: 30,
    scaleMax: 180,
    good: 'Elbows are bent, leaving room to cushion the ball.',
    low: 'Hands are tight to your body, leaving no room to give.',
    high: 'Arms are locked straight; soften your elbows.',
  );

  static const give = MetricSpec(
    id: 'field_give',
    label: 'Give after the catch',
    unit: '%',
    idealMin: 8,
    idealMax: 30,
    tolerance: 10,
    scaleMin: 0,
    scaleMax: 50,
    good: 'Hands give with the ball, taking the pace off it.',
    low: 'Hands stop dead at the catch; let them ride back with the ball.',
    high: 'Hands travel a long way after the catch; stay compact.',
  );

  static const headSteady = MetricSpec(
    id: 'field_head_steady',
    label: 'Head movement into the catch',
    unit: '%',
    idealMin: 0,
    idealMax: 12,
    tolerance: 15,
    scaleMin: 0,
    scaleMax: 40,
    good: 'Head stays steady as the ball arrives.',
    low: 'Head stays steady as the ball arrives.',
    high: 'Head is moving up or down as the ball arrives.',
  );

  @override
  Discipline get discipline => Discipline.fielding;

  @override
  List<MetricSpec> get specs => const [
        handsTogether,
        kneeFlex,
        base,
        headLine,
        softElbows,
        give,
        headSteady,
      ];

  @override
  TechniqueAnalysis analyze(
    List<PoseFrame> frames, {
    required Handedness handedness,
    required double aspectRatio,
  }) {
    final track = BodyTrack(frames, aspectRatio);
    if (track.scale == null) {
      throw const AnalysisException(
        'We could not see your whole body in this clip. Keep head to feet in '
        'the frame.',
      );
    }
    final taken = findTake(
      track,
      notFound: 'We could not find a catch in this clip. Use a clip of one '
          'two-handed catch with both hands in view.',
    );
    final ready = track.indexBefore(taken, 500);
    final settled = track.indexAfter(taken, 300);

    final metrics = <MetricResult>[];
    void add(MetricSpec spec, double? value) {
      if (value != null) metrics.add(spec.evaluate(value));
    }

    add(handsTogether, track.near(taken, (f) => wristGap(track, f)));
    add(kneeFlex, track.near(taken, kneeBend));
    add(base, track.near(taken, (f) => stanceWidth(track, f)));
    add(headLine, track.near(taken, (f) => headToHands(track, f)));
    add(softElbows, track.near(taken, elbowBend));
    add(give, handTravel(track, taken, settled));
    add(headSteady, headTravel(track, ready, taken));

    return TechniqueAnalysis(
      discipline: discipline,
      handedness: handedness,
      metrics: metrics,
      phases: [
        if (ready < taken) PhaseMarker('Ready', track.frames[ready].timeMs),
        PhaseMarker('Catch', track.frames[taken].timeMs),
        if (settled > taken) PhaseMarker('Give', track.frames[settled].timeMs),
      ],
    );
  }
}
