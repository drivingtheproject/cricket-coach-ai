import 'package:material_ui/material_ui.dart';

import '../../core/analysis/metric.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/ball_mark.dart';

/// One measurement: its value, where it sits against the guide range, and
/// what that means.
class MetricBar extends StatelessWidget {
  const MetricBar({super.key, required this.metric});

  final MetricResult metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final good = metric.status == MetricStatus.good;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(metric.label, style: theme.textTheme.titleMedium),
              ),
              Text(metric.valueText, style: AppTheme.numeral(theme, 28)),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: '${metric.label}: ${metric.valueText}. '
                'Guide range ${metric.guideText}.',
            child: CustomPaint(
              size: const Size(double.infinity, 18),
              painter: _RangePainter(
                metric: metric,
                track: scheme.outlineVariant,
                band: scheme.primary,
                ball: good ? scheme.primary : scheme.tertiary,
                seam: good ? scheme.onPrimary : scheme.onTertiary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(metric.note, style: theme.textTheme.bodyMedium),
          Text(
            'Guide range ${metric.guideText}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A pitch-length track with the guide range marked and a ball at the value.
class _RangePainter extends CustomPainter {
  const _RangePainter({
    required this.metric,
    required this.track,
    required this.band,
    required this.ball,
    required this.seam,
  });

  final MetricResult metric;
  final Color track;
  final Color band;
  final Color ball;
  final Color seam;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final left = radius;
    final width = size.width - radius * 2;
    final span = metric.scaleMax - metric.scaleMin;
    double x(double value) {
      final t = span <= 0 ? 0.0 : (value - metric.scaleMin) / span;
      return left + width * t.clamp(0.0, 1.0);
    }

    final centre = size.height / 2;
    final line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..color = track;
    canvas.drawLine(Offset(left, centre), Offset(left + width, centre), line);
    canvas.drawLine(
      Offset(x(metric.idealMin), centre),
      Offset(x(metric.idealMax), centre),
      line
        ..strokeWidth = 8
        ..color = band.withValues(alpha: 0.45),
    );
    BallPainter.paintBall(
      canvas,
      Offset(x(metric.value), centre),
      radius,
      ball,
      seam,
    );
  }

  @override
  bool shouldRepaint(_RangePainter oldDelegate) =>
      oldDelegate.metric != metric ||
      oldDelegate.track != track ||
      oldDelegate.band != band ||
      oldDelegate.ball != ball;
}
