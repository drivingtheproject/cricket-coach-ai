import 'dart:math' as math;

import '../pose/pose_frame.dart';

/// Angle at [b], in degrees (0..180), formed by the points a-b-c.
///
/// Uses x/y only: single-camera depth is too noisy to trust.
/// Returns 0 when either segment has zero length.
double jointAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
  final abx = a.x - b.x;
  final aby = a.y - b.y;
  final cbx = c.x - b.x;
  final cby = c.y - b.y;

  final dot = abx * cbx + aby * cby;
  final magnitude = math.sqrt(abx * abx + aby * aby) *
      math.sqrt(cbx * cbx + cby * cby);
  if (magnitude == 0) return 0;

  final cosine = (dot / magnitude).clamp(-1.0, 1.0);
  return math.acos(cosine) * 180 / math.pi;
}
