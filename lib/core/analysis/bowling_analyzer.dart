import 'dart:math' as math;

import '../analysis_exception.dart';
import '../pose/pose_frame.dart';
import '../sessions/session.dart';
import 'body.dart';
import 'metric.dart';
import 'technique_analysis.dart';
import 'technique_analyzer.dart';

/// Measures a bowling action filmed from side-on.
///
/// Release is taken as the moment the bowling hand is at its highest, and
/// front-foot landing as the moment the front foot stops moving just before
/// that. A 2D view cannot judge whether an action is legal, so the arm
/// measurement is coaching guidance only.
class BowlingAnalyzer implements TechniqueAnalyzer {
  const BowlingAnalyzer();

  /// Bowling-hand speed (body lengths per second) around release below which
  /// no ball was bowled.
  static const double minArmSpeed = 1.5;

  static const armStraightness = MetricSpec(
    id: 'bowl_arm',
    label: 'Bowling arm at release',
    unit: '°',
    idealMin: 160,
    idealMax: 180,
    tolerance: 30,
    scaleMin: 110,
    scaleMax: 180,
    good: 'Bowling arm is long and straight at release.',
    low: 'Bowling arm looks bent at release; reach tall and keep it long.',
    high: 'Bowling arm is long and straight at release.',
  );

  static const releaseHeight = MetricSpec(
    id: 'bowl_release_height',
    label: 'Hand above shoulder at release',
    unit: '%',
    idealMin: 32,
    idealMax: 55,
    tolerance: 20,
    scaleMin: 0,
    scaleMax: 60,
    good: 'You release from a good height.',
    low: 'Release is low; get your arm up beside your ear.',
    high: 'You release from a good height.',
  );

  static const frontKnee = MetricSpec(
    id: 'bowl_front_knee',
    label: 'Front knee at release',
    unit: '°',
    idealMin: 150,
    idealMax: 180,
    tolerance: 35,
    scaleMin: 90,
    scaleMax: 180,
    good: 'Front leg is braced, giving you something to bowl over.',
    low: 'Front knee is collapsing at release, which costs pace and height.',
    high: 'Front leg is braced, giving you something to bowl over.',
  );

  static const trunkLean = MetricSpec(
    id: 'bowl_trunk_lean',
    label: 'Trunk lean at release',
    unit: '°',
    idealMin: 10,
    idealMax: 40,
    tolerance: 20,
    scaleMin: 0,
    scaleMax: 70,
    good: 'Your body is driving forward over the front leg.',
    low: 'You are very upright at release; drive your chest towards the '
        'batter.',
    high: 'You are falling away a long way at release.',
  );

  static const stride = MetricSpec(
    id: 'bowl_stride',
    label: 'Delivery stride length',
    unit: '%',
    idealMin: 50,
    idealMax: 85,
    tolerance: 25,
    scaleMin: 0,
    scaleMax: 120,
    good: 'Delivery stride is a good length.',
    low: 'Delivery stride is short, which limits your momentum.',
    high: 'Delivery stride is very long, which makes it hard to get over '
        'the front leg.',
  );

  static const headLevel = MetricSpec(
    id: 'bowl_head_level',
    label: 'Head movement up and down',
    unit: '%',
    idealMin: 0,
    idealMax: 10,
    tolerance: 12,
    scaleMin: 0,
    scaleMax: 30,
    good: 'Head stays level through the delivery.',
    low: 'Head stays level through the delivery.',
    high: 'Head is dropping or lifting through the delivery.',
  );

  static const followThrough = MetricSpec(
    id: 'bowl_follow_through',
    label: 'Hand below hips at finish',
    unit: '%',
    idealMin: 0,
    idealMax: 45,
    tolerance: 25,
    scaleMin: -40,
    scaleMax: 60,
    good: 'Arm swings all the way through after release.',
    low: 'Arm stops short after release; let it swing through past your hip.',
    high: 'Arm swings all the way through after release.',
  );

  @override
  Discipline get discipline => Discipline.bowling;

  @override
  List<MetricSpec> get specs => const [
        armStraightness,
        releaseHeight,
        frontKnee,
        trunkLean,
        stride,
        headLevel,
        followThrough,
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
    final arm = BodySide.dominant(handedness);
    final front = BodySide.leading(handedness);

    const notFound = AnalysisException(
      'We could not find a delivery in this clip. Use a clip that shows one '
      'ball from the last strides to the follow-through.',
    );
    final handHeight = [
      for (final frame in track.frames) frame.at(arm.wrist)?.y ?? double.nan,
    ];
    final release = track.trough(handHeight);
    if (release == null) throw notFound;
    final shoulderAtRelease = track.frames[release].at(arm.shoulder);
    if (shoulderAtRelease == null ||
        handHeight[release] >= shoulderAtRelease.y) {
      throw notFound;
    }
    final handSpeed = track.speedOf((frame) => frame.at(arm.wrist));
    final fastest = track.peak(
      handSpeed,
      from: track.indexBefore(release, 250),
      to: track.indexAfter(release, 250) + 1,
    )!;
    if (handSpeed[fastest] < minArmSpeed) throw notFound;

    final footSpeed = track.speedOf((frame) => frame.at(front.ankle));
    final landing = track.trough(
          footSpeed,
          from: track.indexBefore(release, 400),
          to: release + 1,
        ) ??
        release;
    final finish = track.settleIndex(handSpeed, fastest);

    final metrics = <MetricResult>[];
    void add(MetricSpec spec, double? value) {
      if (value != null) metrics.add(spec.evaluate(value));
    }

    add(
      armStraightness,
      track.near(release, (f) => f.angle(arm.shoulder, arm.elbow, arm.wrist)),
    );
    add(
      releaseHeight,
      track.near(release, (f) {
        final hand = f.at(arm.wrist);
        final shoulder = f.at(arm.shoulder);
        return hand == null || shoulder == null
            ? null
            : track.percentOfBody(shoulder.y - hand.y);
      }),
    );
    add(
      frontKnee,
      track.near(release, (f) => f.angle(front.hip, front.knee, front.ankle)),
    );
    add(
      trunkLean,
      track.near(release, (f) {
        final shoulders = f.shoulders;
        final hips = f.hips;
        if (shoulders == null || hips == null) return null;
        return math.atan2(
              (shoulders.x - hips.x).abs(),
              (hips.y - shoulders.y).abs(),
            ) *
            180 /
            math.pi;
      }),
    );
    add(
      stride,
      track.near(landing, (f) {
        final a = f.at(front.ankle);
        final b = f.at(arm.ankle);
        return a == null || b == null
            ? null
            : track.percentOfBody((a.x - b.x).abs());
      }),
    );
    add(headLevel, headTravel(track, landing, release));
    add(
      followThrough,
      track.near(finish, (f) {
        final hand = f.at(arm.wrist);
        final hips = f.hips;
        return hand == null || hips == null
            ? null
            : track.percentOfBody(hand.y - hips.y);
      }),
    );

    if (metrics.isEmpty) {
      throw const AnalysisException(
        'We could not measure this delivery. Film from side-on in good '
        'light with your whole body in the frame.',
      );
    }

    return TechniqueAnalysis(
      discipline: discipline,
      handedness: handedness,
      metrics: metrics,
      phases: [
        if (landing < release)
          PhaseMarker('Front foot lands', track.frames[landing].timeMs),
        PhaseMarker('Release', track.frames[release].timeMs),
        if (finish > release)
          PhaseMarker('Follow-through', track.frames[finish].timeMs),
      ],
    );
  }
}
