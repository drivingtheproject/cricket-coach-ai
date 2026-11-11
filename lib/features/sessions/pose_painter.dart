import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/pose/pose_frame.dart';
import '../../core/pose/skeleton.dart';

/// Draws the tracked skeleton over a video frame.
class PosePainter extends CustomPainter {
  const PosePainter({
    required this.frame,
    required this.boneColor,
    required this.jointColor,
    this.minVisibility = 0.5,
  });

  final PoseFrame? frame;
  final Color boneColor;
  final Color jointColor;

  /// Landmarks the detector is less sure of than this are not drawn.
  final double minVisibility;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = this.frame;
    if (frame == null || frame.landmarks.length < PoseLandmarkIndex.count) {
      return;
    }
    final width = math.max(2.0, size.shortestSide * 0.008);
    final outline = Paint()
      ..color = const Color(0x99000000)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width + 2;
    final bone = Paint()
      ..color = boneColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;
    final joint = Paint()..color = jointColor;

    Offset point(int index) =>
        Offset(frame[index].x * size.width, frame[index].y * size.height);
    bool visible(int index) => frame[index].visibility >= minVisibility;

    // A dark outline first keeps the skeleton readable on any background.
    for (final paint in [outline, bone]) {
      for (final (a, b) in skeletonBones) {
        if (visible(a) && visible(b)) {
          canvas.drawLine(point(a), point(b), paint);
        }
      }
    }
    for (final index in skeletonJoints) {
      if (visible(index)) canvas.drawCircle(point(index), width * 1.4, joint);
    }
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.boneColor != boneColor ||
      oldDelegate.jointColor != jointColor;
}
