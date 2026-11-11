import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A cricket ball with its seam. Used as the app mark and as the marker on
/// metric range bars.
class BallMark extends StatelessWidget {
  const BallMark({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.square(size),
      painter: BallPainter(ball: color ?? scheme.tertiary, seam: scheme.onTertiary),
    );
  }
}

class BallPainter extends CustomPainter {
  const BallPainter({required this.ball, required this.seam});

  final Color ball;
  final Color seam;

  @override
  void paint(Canvas canvas, Size size) {
    paintBall(canvas, size.center(Offset.zero), size.shortestSide / 2, ball, seam);
  }

  /// Draws a ball at [center]; shared with painters that place a ball marker.
  static void paintBall(
    Canvas canvas,
    Offset center,
    double radius,
    Color ball,
    Color seam,
  ) {
    canvas.drawCircle(center, radius, Paint()..color = ball);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    final seamPaint = Paint()
      ..color = seam.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, radius * 0.12);
    // The seam is the visible arc of a larger circle centred to the right.
    canvas.drawCircle(
      center + Offset(radius * 1.25, 0),
      radius * 1.45,
      seamPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BallPainter oldDelegate) =>
      oldDelegate.ball != ball || oldDelegate.seam != seam;
}
