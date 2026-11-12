import 'dart:math' as math;

import '../analysis_exception.dart';
import '../pose/pose_frame.dart';
import '../sessions/session.dart';
import 'body.dart';
import 'metric.dart';
import 'technique_analysis.dart';
import 'technique_analyzer.dart';

/// Measures a batting shot filmed from side-on.
///
/// The moments are found from how the hands move: impact is where they move
/// fastest, the top of the backlift is where they were highest just before
/// that, and the finish is where they slow down again.
class BattingAnalyzer implements TechniqueAnalyzer {
  const BattingAnalyzer();

  /// Hand speed (body lengths per second) below which no shot was played.
  static const double minSwingSpeed = 1.0;

  static const frontKnee = MetricSpec(
    id: 'front_knee',
    label: 'Front knee bend at impact',
    unit: '°',
    idealMin: 115,
    idealMax: 155,
    tolerance: 35,
    scaleMin: 70,
    scaleMax: 180,
    good: 'Front knee is bent and firm, so your weight is going into the shot.',
    low: 'Front knee is bending too far and collapsing under you.',
    high: 'Front leg is too straight, which keeps your weight back.',
  );

  static const frontElbow = MetricSpec(
    id: 'front_elbow',
    label: 'Front elbow at impact',
    unit: '°',
    idealMin: 85,
    idealMax: 135,
    tolerance: 40,
    scaleMin: 30,
    scaleMax: 180,
    good: 'Front elbow is bent and high, keeping the bat straight.',
    low: 'Front elbow is tucked in too tightly, cramping the swing.',
    high: 'Front arm is locked straight; let the elbow bend and lead.',
  );

  static const headOverFoot = MetricSpec(
    id: 'head_over_front_foot',
    label: 'Head from front foot at impact',
    unit: '%',
    idealMin: 0,
    idealMax: 15,
    tolerance: 25,
    scaleMin: 0,
    scaleMax: 50,
    good: 'Head is over the front foot at impact.',
    low: 'Head is over the front foot at impact.',
    high: 'Head is falling away from the front foot instead of over it.',
  );

  static const stride = MetricSpec(
    id: 'stride',
    label: 'Stride length',
    unit: '%',
    idealMin: 30,
    idealMax: 60,
    tolerance: 25,
    scaleMin: 0,
    scaleMax: 90,
    good: 'Stride is a comfortable length.',
    low: 'Stride is short; step further towards the ball.',
    high: 'Stride is very long, which makes it hard to stay balanced.',
  );

  static const backlift = MetricSpec(
    id: 'backlift',
    label: 'Backlift height above hips',
    unit: '%',
    idealMin: 22,
    idealMax: 50,
    tolerance: 20,
    scaleMin: 0,
    scaleMax: 70,
    good: 'Hands reach a good height in the backlift.',
    low: 'Backlift is low; lift the hands to around shoulder height.',
    high: 'Backlift is very high, which can make you late on the ball.',
  );

  static const headLevel = MetricSpec(
    id: 'head_level',
    label: 'Head movement up and down',
    unit: '%',
    idealMin: 0,
    idealMax: 8,
    tolerance: 12,
    scaleMin: 0,
    scaleMax: 25,
    good: 'Head stays level through the shot.',
    low: 'Head stays level through the shot.',
    high: 'Head is bobbing up or down during the swing.',
  );

  static const finishBalance = MetricSpec(
    id: 'finish_balance',
    label: 'Head outside the feet at finish',
    unit: '%',
    idealMin: 0,
    idealMax: 5,
    tolerance: 15,
    scaleMin: 0,
    scaleMax: 25,
    good: 'You finish balanced, with your head between your feet.',
    low: 'You finish balanced, with your head between your feet.',
    high: 'You are falling over at the finish; hold your shape.',
  );

  @override
  Discipline get discipline => Discipline.batting;

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

    final handSpeed = track.speedOf((frame) => frame.wrists);
    final impact = track.peak(handSpeed);
    if (impact == null || handSpeed[impact] < minSwingSpeed) {
      throw const AnalysisException(
        'We could not find a shot in this clip. Use a clip that shows one '
        'full swing.',
      );
    }

    // Top of the backlift: hands at their highest in the 1.5 s before impact.
    final handHeight = [
      for (final frame in track.frames) frame.wrists?.y ?? double.nan,
    ];
    final top = track.trough(
          handHeight,
          from: track.indexBefore(impact, 1500),
          to: impact,
        ) ??
        impact;
    // Stance: hands at their stillest before the backlift.
    final stance = track.trough(handSpeed, to: top) ?? top;
    // Finish: hands have slowed to a fifth of their top speed.
    var finish = track.length - 1;
    for (var i = impact + 1; i < track.length; i++) {
      if (handSpeed[i] < handSpeed[impact] * 0.2) {
        finish = i;
        break;
      }
    }

    final front = BodySide.leading(handedness);
    final back = BodySide.dominant(handedness);
    final metrics = <MetricResult>[];
    void add(MetricSpec spec, double? value) {
      if (value != null) metrics.add(spec.evaluate(value));
    }

    add(
      frontKnee,
      track.near(impact, (f) => f.angle(front.hip, front.knee, front.ankle)),
    );
    add(
      frontElbow,
      track.near(
        impact,
        (f) => f.angle(front.shoulder, front.elbow, front.wrist),
      ),
    );
    add(
      headOverFoot,
      track.near(impact, (f) {
        final head = f.head;
        final foot = f.at(front.ankle);
        return head == null || foot == null
            ? null
            : track.percentOfBody((head.x - foot.x).abs());
      }),
    );
    add(
      stride,
      track.near(impact, (f) {
        final frontFoot = f.at(front.ankle);
        final backFoot = f.at(back.ankle);
        return frontFoot == null || backFoot == null
            ? null
            : track.percentOfBody((frontFoot.x - backFoot.x).abs());
      }),
    );
    add(
      backlift,
      track.near(top, (f) {
        final hands = f.wrists;
        final hips = f.hips;
        return hands == null || hips == null
            ? null
            : track.percentOfBody(hips.y - hands.y);
      }),
    );
    add(headLevel, _headTravel(track, top, impact));
    add(
      finishBalance,
      track.near(finish, (f) {
        final head = f.head;
        final a = f.at(front.ankle);
        final b = f.at(back.ankle);
        if (head == null || a == null || b == null) return null;
        final outside = math.max(
          math.min(a.x, b.x) - head.x,
          head.x - math.max(a.x, b.x),
        );
        return track.percentOfBody(math.max(0, outside));
      }),
    );

    if (metrics.isEmpty) {
      throw const AnalysisException(
        'We could not measure this shot. Film from side-on in good light '
        'with your whole body in the frame.',
      );
    }

    return TechniqueAnalysis(
      discipline: discipline,
      handedness: handedness,
      metrics: metrics,
      phases: [
        if (stance < top) PhaseMarker('Stance', track.frames[stance].timeMs),
        if (top < impact) PhaseMarker('Backlift', track.frames[top].timeMs),
        PhaseMarker('Impact', track.frames[impact].timeMs),
        if (finish > impact) PhaseMarker('Finish', track.frames[finish].timeMs),
      ],
    );
  }

  /// How far the head moved up and down between two frames, as a percentage
  /// of body length.
  static double? _headTravel(BodyTrack track, int from, int to) {
    double? lowest;
    double? highest;
    for (var i = from; i <= to; i++) {
      final y = track.frames[i].head?.y;
      if (y == null) continue;
      lowest = lowest == null ? y : math.min(lowest, y);
      highest = highest == null ? y : math.max(highest, y);
    }
    return lowest == null ? null : track.percentOfBody(highest! - lowest);
  }
}
