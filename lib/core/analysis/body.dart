import 'dart:math' as math;

import '../pose/pose_frame.dart';
import '../sessions/session.dart';

/// A point in image-height units, so distances and angles are true to the
/// picture whatever its aspect ratio.
class Pt {
  const Pt(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(Pt other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static Pt mid(Pt a, Pt b) => Pt((a.x + b.x) / 2, (a.y + b.y) / 2);
}

/// Angle at [b] in degrees (0..180) formed by a-b-c.
double angleBetween(Pt a, Pt b, Pt c) {
  final abx = a.x - b.x;
  final aby = a.y - b.y;
  final cbx = c.x - b.x;
  final cby = c.y - b.y;
  final magnitude = math.sqrt(abx * abx + aby * aby) *
      math.sqrt(cbx * cbx + cby * cby);
  if (magnitude == 0) return 0;
  final cosine = ((abx * cbx + aby * cby) / magnitude).clamp(-1.0, 1.0);
  return math.acos(cosine) * 180 / math.pi;
}

/// The landmark indexes of one side of the body.
class BodySide {
  const BodySide._({
    required this.shoulder,
    required this.elbow,
    required this.wrist,
    required this.hip,
    required this.knee,
    required this.ankle,
  });

  static const BodySide left = BodySide._(
    shoulder: PoseLandmarkIndex.leftShoulder,
    elbow: PoseLandmarkIndex.leftElbow,
    wrist: PoseLandmarkIndex.leftWrist,
    hip: PoseLandmarkIndex.leftHip,
    knee: PoseLandmarkIndex.leftKnee,
    ankle: PoseLandmarkIndex.leftAnkle,
  );

  static const BodySide right = BodySide._(
    shoulder: PoseLandmarkIndex.rightShoulder,
    elbow: PoseLandmarkIndex.rightElbow,
    wrist: PoseLandmarkIndex.rightWrist,
    hip: PoseLandmarkIndex.rightHip,
    knee: PoseLandmarkIndex.rightKnee,
    ankle: PoseLandmarkIndex.rightAnkle,
  );

  /// The side of the player's dominant hand.
  static BodySide dominant(Handedness hand) =>
      hand == Handedness.right ? right : left;

  /// The side opposite the dominant hand. For a batter this is the front
  /// (leading) side; for a bowler it is the front arm and front leg.
  static BodySide leading(Handedness hand) =>
      hand == Handedness.right ? left : right;

  final int shoulder;
  final int elbow;
  final int wrist;
  final int hip;
  final int knee;
  final int ankle;
}

/// One frame's landmarks, ignoring points the detector was unsure of.
class BodyFrame {
  const BodyFrame(this.frame, this.aspectRatio, {this.minVisibility = 0.5});

  final PoseFrame frame;
  final double aspectRatio;
  final double minVisibility;

  int get timeMs => frame.timestampMs;

  Pt? at(int index) {
    if (index >= frame.landmarks.length) return null;
    final point = frame[index];
    if (point.visibility < minVisibility) return null;
    return Pt(point.x * aspectRatio, point.y);
  }

  Pt? midOf(int a, int b) {
    final first = at(a);
    final second = at(b);
    return first == null || second == null ? null : Pt.mid(first, second);
  }

  Pt? get head => at(PoseLandmarkIndex.nose);
  Pt? get shoulders =>
      midOf(PoseLandmarkIndex.leftShoulder, PoseLandmarkIndex.rightShoulder);
  Pt? get hips => midOf(PoseLandmarkIndex.leftHip, PoseLandmarkIndex.rightHip);
  Pt? get wrists =>
      midOf(PoseLandmarkIndex.leftWrist, PoseLandmarkIndex.rightWrist);
  Pt? get ankles =>
      midOf(PoseLandmarkIndex.leftAnkle, PoseLandmarkIndex.rightAnkle);

  /// Angle at landmark [b] formed by landmarks a-b-c, in degrees.
  double? angle(int a, int b, int c) {
    final pa = at(a);
    final pb = at(b);
    final pc = at(c);
    return pa == null || pb == null || pc == null
        ? null
        : angleBetween(pa, pb, pc);
  }

  /// Shoulder-to-ankle length of one side: torso + thigh + shin.
  double? sideLength(BodySide side) {
    final shoulder = at(side.shoulder);
    final hip = at(side.hip);
    final knee = at(side.knee);
    final ankle = at(side.ankle);
    if (shoulder == null || hip == null || knee == null || ankle == null) {
      return null;
    }
    return shoulder.distanceTo(hip) +
        hip.distanceTo(knee) +
        knee.distanceTo(ankle);
  }
}

/// A whole clip's frames with helpers for finding moments in the movement.
class BodyTrack {
  BodyTrack(List<PoseFrame> frames, double aspectRatio)
      : frames = [for (final frame in frames) BodyFrame(frame, aspectRatio)] {
    scale = _medianScale();
  }

  final List<BodyFrame> frames;

  /// The player's shoulder-to-ankle length, used as the unit for distances so
  /// results do not depend on how far away the camera was. Null when the
  /// body was never seen from shoulder to ankle.
  late final double? scale;

  int get length => frames.length;

  /// [distance] as a percentage of the player's shoulder-to-ankle length.
  double percentOfBody(double distance) => distance / scale! * 100;

  /// Speed of a point at each frame, in body lengths per second, lightly
  /// smoothed. Frames where the point is unknown get 0.
  List<double> speedOf(Pt? Function(BodyFrame frame) point) {
    final bodyLength = scale;
    if (bodyLength == null) return List.filled(length, 0);
    final raw = List<double>.filled(length, 0);
    for (var i = 0; i < length; i++) {
      final before = i > 0 ? i - 1 : i;
      final after = i < length - 1 ? i + 1 : i;
      final a = point(frames[before]);
      final b = point(frames[after]);
      final seconds = (frames[after].timeMs - frames[before].timeMs) / 1000;
      if (a == null || b == null || seconds <= 0) continue;
      raw[i] = a.distanceTo(b) / bodyLength / seconds;
    }
    return [
      for (var i = 0; i < length; i++)
        (raw[math.max(0, i - 1)] + raw[i] + raw[math.min(length - 1, i + 1)]) /
            3,
    ];
  }

  /// Index of the largest value in `[from, to)`, or null for an empty range.
  int? peak(List<double> values, {int from = 0, int? to}) =>
      _best(values, from, to, (a, b) => a > b);

  /// Index of the smallest value in `[from, to)`, or null for an empty range.
  int? trough(List<double> values, {int from = 0, int? to}) =>
      _best(values, from, to, (a, b) => a < b);

  /// First index at or after the time [ms] before frame [index].
  int indexBefore(int index, int ms) {
    final target = frames[index].timeMs - ms;
    var i = index;
    while (i > 0 && frames[i - 1].timeMs >= target) {
      i--;
    }
    return i;
  }

  /// Reads a value at [index], falling back to the neighbouring frames when
  /// the landmarks it needs are hidden there.
  double? near(int index, double? Function(BodyFrame frame) read) {
    for (final offset in const [0, -1, 1, -2, 2]) {
      final i = index + offset;
      if (i < 0 || i >= length) continue;
      final value = read(frames[i]);
      if (value != null) return value;
    }
    return null;
  }

  int? _best(
    List<double> values,
    int from,
    int? to,
    bool Function(double a, double b) better,
  ) {
    final end = math.min(to ?? values.length, values.length);
    int? best;
    for (var i = math.max(0, from); i < end; i++) {
      if (values[i].isNaN) continue;
      if (best == null || better(values[i], values[best])) best = i;
    }
    return best;
  }

  double? _medianScale() {
    final lengths = <double>[];
    for (final frame in frames) {
      final left = frame.sideLength(BodySide.left);
      final right = frame.sideLength(BodySide.right);
      if (left != null && right != null) {
        lengths.add((left + right) / 2);
      } else if (left != null || right != null) {
        lengths.add(left ?? right!);
      }
    }
    if (lengths.isEmpty) return null;
    lengths.sort();
    final median = lengths[lengths.length ~/ 2];
    return median > 0 ? median : null;
  }
}
