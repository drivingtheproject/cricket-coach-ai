import 'package:material_ui/material_ui.dart';

import '../../core/progress/progress_summary.dart';
import '../../widgets/ball_mark.dart';

/// Technique scores over time: one dot per session, oldest on the left, with
/// the latest marked by the ball.
class ScoreChart extends StatelessWidget {
  const ScoreChart({super.key, required this.points});

  final List<ScorePoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: 'Chart of ${points.length} technique scores. '
          'Latest ${points.last.score.round()} out of 100.',
      child: CustomPaint(
        size: const Size(double.infinity, 180),
        painter: _ScoreChartPainter(
          scores: [for (final point in points) point.score],
          line: scheme.primary,
          grid: scheme.outlineVariant,
          ball: scheme.tertiary,
          seam: scheme.onTertiary,
          labelStyle: theme.textTheme.bodySmall!.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  const _ScoreChartPainter({
    required this.scores,
    required this.line,
    required this.grid,
    required this.ball,
    required this.seam,
    required this.labelStyle,
  });

  final List<double> scores;
  final Color line;
  final Color grid;
  final Color ball;
  final Color seam;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const labelWidth = 32.0;
    const pad = 10.0;
    final left = labelWidth;
    final right = size.width - pad;
    final top = pad;
    final bottom = size.height - pad;

    double y(double score) =>
        bottom - (bottom - top) * (score.clamp(0, 100) / 100);
    double x(int index) => scores.length == 1
        ? (left + right) / 2
        : left + (right - left) * index / (scores.length - 1);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final mark in const [0.0, 50.0, 100.0]) {
      canvas.drawLine(Offset(left, y(mark)), Offset(right, y(mark)), gridPaint);
      final label = TextPainter(
        text: TextSpan(text: '${mark.round()}', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, y(mark) - label.height / 2));
    }

    final path = Path();
    for (var i = 0; i < scores.length; i++) {
      final point = Offset(x(i), y(scores[i]));
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = line;
    for (var i = 0; i < scores.length - 1; i++) {
      canvas.drawCircle(Offset(x(i), y(scores[i])), 3.5, dot);
    }
    BallPainter.paintBall(
      canvas,
      Offset(x(scores.length - 1), y(scores.last)),
      8,
      ball,
      seam,
    );
  }

  @override
  bool shouldRepaint(_ScoreChartPainter oldDelegate) =>
      oldDelegate.scores != scores ||
      oldDelegate.line != line ||
      oldDelegate.grid != grid;
}
