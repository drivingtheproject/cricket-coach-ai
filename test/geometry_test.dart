import 'package:cricket_coach_ai/core/metrics/geometry.dart';
import 'package:cricket_coach_ai/core/pose/pose_frame.dart';
import 'package:flutter_test/flutter_test.dart';

PoseLandmark p(double x, double y) => PoseLandmark(x: x, y: y);

void main() {
  group('jointAngle', () {
    test('right angle is 90 degrees', () {
      expect(jointAngle(p(0, 1), p(0, 0), p(1, 0)), closeTo(90, 1e-9));
    });

    test('straight limb is 180 degrees', () {
      expect(jointAngle(p(-1, 0), p(0, 0), p(1, 0)), closeTo(180, 1e-9));
    });

    test('folded limb is 0 degrees', () {
      expect(jointAngle(p(1, 0), p(0, 0), p(2, 0)), closeTo(0, 1e-9));
    });

    test('zero-length segment returns 0 instead of NaN', () {
      expect(jointAngle(p(0, 0), p(0, 0), p(1, 0)), 0);
    });
  });
}
