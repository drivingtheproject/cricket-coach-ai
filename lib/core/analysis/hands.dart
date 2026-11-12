import 'dart:math' as math;

import '../analysis_exception.dart';
import '../pose/pose_frame.dart';
import 'body.dart';

/// Helpers for movements where both hands take the ball: catching and
/// wicketkeeping.

/// Gap between the wrists at each frame as a percentage of body length; NaN
/// where a wrist is hidden.
List<double> wristGaps(BodyTrack track) => [
      for (final frame in track.frames) wristGap(track, frame) ?? double.nan,
    ];

double? wristGap(BodyTrack track, BodyFrame frame) {
  final left = frame.at(PoseLandmarkIndex.leftWrist);
  final right = frame.at(PoseLandmarkIndex.rightWrist);
  return left == null || right == null
      ? null
      : track.percentOfBody(left.distanceTo(right));
}

/// Gap between the ankles as a percentage of body length.
double? stanceWidth(BodyTrack track, BodyFrame frame) {
  final left = frame.at(PoseLandmarkIndex.leftAnkle);
  final right = frame.at(PoseLandmarkIndex.rightAnkle);
  return left == null || right == null
      ? null
      : track.percentOfBody(left.distanceTo(right));
}

/// Sideways distance between the head and the hands, as a percentage of body
/// length.
double? headToHands(BodyTrack track, BodyFrame frame) {
  final head = frame.head;
  final hands = frame.wrists;
  return head == null || hands == null
      ? null
      : track.percentOfBody((head.x - hands.x).abs());
}

/// Mean of the left and right knee angles (whichever are visible).
double? kneeBend(BodyFrame frame) => _mean([
      for (final side in const [BodySide.left, BodySide.right])
        frame.angle(side.hip, side.knee, side.ankle),
    ]);

/// Mean of the left and right elbow angles (whichever are visible).
double? elbowBend(BodyFrame frame) => _mean([
      for (final side in const [BodySide.left, BodySide.right])
        frame.angle(side.shoulder, side.elbow, side.wrist),
    ]);

/// How far the hands travelled between two frames, as a percentage of body
/// length.
double? handTravel(BodyTrack track, int from, int to) {
  var total = 0.0;
  Pt? previous;
  for (var i = from; i <= math.min(to, track.length - 1); i++) {
    final hands = track.frames[i].wrists;
    if (hands == null) continue;
    if (previous != null) total += previous.distanceTo(hands);
    previous = hands;
  }
  return previous == null ? null : track.percentOfBody(total);
}

/// Finds the frame where the ball is taken: the hands move towards it, then
/// come together. Throws [AnalysisException] with [notFound] when the hands
/// never move or never close.
int findTake(
  BodyTrack track, {
  required String notFound,
  double minHandSpeed = 0.5,
  double maxGap = 20,
}) {
  final speed = track.speedOf((frame) => frame.wrists);
  final reach = track.peak(speed);
  if (reach == null || speed[reach] < minHandSpeed) {
    throw AnalysisException(notFound);
  }
  final gaps = wristGaps(track);
  final take = track.trough(
    gaps,
    from: reach,
    to: track.indexAfter(reach, 400) + 1,
  );
  if (take == null || gaps[take] > maxGap) throw AnalysisException(notFound);
  return take;
}

double? _mean(List<double?> values) {
  final known = values.whereType<double>().toList();
  if (known.isEmpty) return null;
  return known.reduce((a, b) => a + b) / known.length;
}
