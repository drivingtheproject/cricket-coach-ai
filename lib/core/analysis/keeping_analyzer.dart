import 'dart:math' as math;

import '../analysis_exception.dart';
import '../pose/pose_frame.dart';
import '../sessions/session.dart';
import 'body.dart';
import 'hands.dart';
import 'metric.dart';
import 'technique_analysis.dart';
import 'technique_analyzer.dart';

/// Measures a wicketkeeper taking one ball, filmed from in front or from the
/// side.
///
/// The set position is the deepest point of the crouch before the take, and
/// the take is the moment the gloves close after reaching for the ball.
class KeepingAnalyzer implements TechniqueAnalyzer {
  const KeepingAnalyzer();

  static const crouch = MetricSpec(
    id: 'keep_crouch',
    label: 'Knee bend in the set position',
    unit: '°',
    idealMin: 40,
    idealMax: 100,
    tolerance: 40,
    scaleMin: 20,
    scaleMax: 180,
    good: 'You are set low, with your eyes near the line of the ball.',
    low: 'You are sitting right down on your heels, which slows your rise.',
    high: 'You are standing tall in the set position; get lower.',
  );

  static const stance = MetricSpec(
    id: 'keep_stance',
    label: 'Width of stance',
    unit: '%',
    idealMin: 22,
    idealMax: 55,
    tolerance: 20,
    scaleMin: 0,
    scaleMax: 90,
    good: 'Feet are a comfortable width, ready to move either way.',
    low: 'Feet are close together, which makes it hard to push sideways.',
    high: 'Feet are very wide, which slows your first step.',
  );

  static const rise = MetricSpec(
    id: 'keep_rise',
    label: 'Head rise before the take',
    unit: '%',
    idealMin: 0,
    idealMax: 30,
    tolerance: 25,
    scaleMin: 0,
    scaleMax: 70,
    good: 'You stay down and come up with the ball.',
    low: 'You stay down and come up with the ball.',
    high: 'You are standing up before the ball arrives; rise with the '
        'bounce.',
  );

  static const glovesTogether = MetricSpec(
    id: 'keep_gloves_together',
    label: 'Gap between gloves at the take',
    unit: '%',
    idealMin: 0,
    idealMax: 12,
    tolerance: 15,
    scaleMin: 0,
    scaleMax: 40,
    good: 'Gloves are together, giving the ball one big target.',
    low: 'Gloves are together, giving the ball one big target.',
    high: 'Gloves are apart at the take; keep the little fingers together.',
  );

  static const headLine = MetricSpec(
    id: 'keep_head_line',
    label: 'Head from gloves at the take',
    unit: '%',
    idealMin: 0,
    idealMax: 15,
    tolerance: 20,
    scaleMin: 0,
    scaleMax: 50,
    good: 'Head is in line with the gloves, so your eyes follow the ball in.',
    low: 'Head is in line with the gloves, so your eyes follow the ball in.',
    high: 'You are taking the ball away from your head; move your feet '
        'first.',
  );

  static const elbows = MetricSpec(
    id: 'keep_elbows',
    label: 'Elbow bend at the take',
    unit: '°',
    idealMin: 90,
    idealMax: 160,
    tolerance: 30,
    scaleMin: 30,
    scaleMax: 180,
    good: 'Elbows are relaxed and clear of your body.',
    low: 'Elbows are tucked in, leaving no room to give with the ball.',
    high: 'Arms are locked straight; relax your elbows.',
  );

  static const give = MetricSpec(
    id: 'keep_give',
    label: 'Give after the take',
    unit: '%',
    idealMin: 5,
    idealMax: 30,
    tolerance: 10,
    scaleMin: 0,
    scaleMax: 50,
    good: 'Gloves give with the ball, so it stays in.',
    low: 'Gloves stop dead at the take, so the ball can bounce out.',
    high: 'Gloves travel a long way after the take; stay compact.',
  );

  @override
  Discipline get discipline => Discipline.wicketkeeping;

  @override
  List<MetricSpec> get specs => const [
        crouch,
        stance,
        rise,
        glovesTogether,
        headLine,
        elbows,
        give,
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
      notFound: 'We could not find a take in this clip. Use a clip of one '
          'ball, from the set position until the ball is in the gloves.',
    );
    // Set position: hips at their lowest before the take.
    final hipHeight = [
      for (final frame in track.frames) frame.hips?.y ?? double.nan,
    ];
    final set = track.peak(hipHeight, to: taken + 1) ?? taken;
    final settled = track.indexAfter(taken, 300);

    final metrics = <MetricResult>[];
    void add(MetricSpec spec, double? value) {
      if (value != null) metrics.add(spec.evaluate(value));
    }

    add(crouch, track.near(set, kneeBend));
    add(stance, track.near(set, (f) => stanceWidth(track, f)));
    final headAtSet = track.near(set, (f) => f.head?.y);
    final headAtTake = track.near(taken, (f) => f.head?.y);
    if (headAtSet != null && headAtTake != null) {
      add(rise, track.percentOfBody(math.max(0, headAtSet - headAtTake)));
    }
    add(glovesTogether, track.near(taken, (f) => wristGap(track, f)));
    add(headLine, track.near(taken, (f) => headToHands(track, f)));
    add(elbows, track.near(taken, elbowBend));
    add(give, handTravel(track, taken, settled));

    return TechniqueAnalysis(
      discipline: discipline,
      handedness: handedness,
      metrics: metrics,
      phases: [
        if (set < taken) PhaseMarker('Set', track.frames[set].timeMs),
        PhaseMarker('Take', track.frames[taken].timeMs),
        if (settled > taken) PhaseMarker('Give', track.frames[settled].timeMs),
      ],
    );
  }
}
