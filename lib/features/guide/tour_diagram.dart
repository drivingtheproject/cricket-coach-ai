import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/guide/filming_tour.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/ball_mark.dart';

/// The picture for one step of a filming tour.
class TourDiagramView extends StatelessWidget {
  const TourDiagramView({super.key, required this.tour, required this.step});

  final FilmingTour tour;
  final TourStep step;

  String get _description => switch (step.diagram) {
        TourDiagram.cameraPosition =>
          'Diagram: camera ${tour.view.label.toLowerCase()} to the player, '
              '${tour.distance} away.',
        TourDiagram.framing =>
          'Diagram: the whole player inside the phone frame, camera at '
              '${tour.height.toLowerCase()}.',
        TourDiagram.moments =>
          'Diagram: the clip runs through ${tour.moments.join(', ')}.',
        TourDiagram.steady =>
          'Diagram: phone on a stand with the light behind it.',
        TourDiagram.checklist => 'Checklist.',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: _description,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: CustomPaint(
            painter: _TourPainter(
              tour: tour,
              diagram: step.diagram,
              ink: scheme.onSurface,
              muted: scheme.onSurfaceVariant,
              accent: scheme.primary,
              ball: scheme.tertiary,
              seam: scheme.onTertiary,
              surface: scheme.surface,
              label: theme.textTheme.labelLarge!,
            ),
          ),
        ),
      ),
    );
  }
}

class _TourPainter extends CustomPainter {
  const _TourPainter({
    required this.tour,
    required this.diagram,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.ball,
    required this.seam,
    required this.surface,
    required this.label,
  });

  final FilmingTour tour;
  final TourDiagram diagram;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color ball;
  final Color seam;
  final Color surface;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    switch (diagram) {
      case TourDiagram.cameraPosition:
        _position(canvas, size);
      case TourDiagram.framing:
        _framing(canvas, size);
      case TourDiagram.moments:
        _moments(canvas, size);
      case TourDiagram.steady:
        _steady(canvas, size);
      case TourDiagram.checklist:
        _checklist(canvas, size);
    }
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _text(
    Canvas canvas,
    String text,
    Offset centre, {
    Color? color,
    double maxWidth = 200,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: label.copyWith(color: color ?? ink)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _dashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    final length = (to - from).distance;
    final direction = (to - from) / length;
    for (var d = 0.0; d < length; d += 10) {
      canvas.drawLine(
        from + direction * d,
        from + direction * math.min(d + 5, length),
        paint,
      );
    }
  }

  void _phone(Canvas canvas, Offset centre, double width, {double turn = 0}) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(turn);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: width, height: width * 0.55),
      Radius.circular(width * 0.1),
    );
    canvas.drawRRect(body, Paint()..color = ink);
    canvas.drawCircle(
      Offset(width * 0.28, 0),
      width * 0.1,
      Paint()..color = surface,
    );
    canvas.restore();
  }

  /// A simple figure standing with its feet at [feet].
  void _figure(Canvas canvas, Offset feet, double height, {Color? color}) {
    final paint = _stroke(color ?? ink, math.max(2.5, height * 0.045));
    final head = feet - Offset(0, height * 0.9);
    final neck = feet - Offset(0, height * 0.8);
    final hip = feet - Offset(0, height * 0.42);
    canvas.drawCircle(head, height * 0.09, Paint()..color = color ?? ink);
    canvas.drawLine(neck, hip, paint);
    canvas.drawLine(hip, feet - Offset(height * 0.14, 0), paint);
    canvas.drawLine(hip, feet + Offset(height * 0.14, 0), paint);
    canvas.drawLine(
      neck + Offset(0, height * 0.06),
      neck + Offset(height * 0.2, height * 0.2),
      paint,
    );
    canvas.drawLine(
      neck + Offset(0, height * 0.06),
      neck + Offset(-height * 0.2, height * 0.2),
      paint,
    );
  }

  /// Seen from above: the pitch, the player on it and where the camera goes.
  void _position(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sideOn = tour.view == CameraView.sideOn;
    final pitch = sideOn
        ? Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.3),
            width: w * 0.8,
            height: h * 0.2,
          )
        : Rect.fromCenter(
            center: Offset(w * 0.3, h * 0.5),
            width: w * 0.2,
            height: h * 0.8,
          );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pitch, const Radius.circular(4)),
      Paint()..color = AppColors.pitchStraw,
    );

    final player = sideOn
        ? Offset(pitch.left + pitch.width * 0.7, pitch.center.dy)
        : Offset(pitch.center.dx, pitch.top + pitch.height * 0.3);
    final camera = sideOn
        ? Offset(player.dx, h * 0.82)
        : Offset(pitch.center.dx + w * 0.07, pitch.top + pitch.height * 0.85);

    // Crease line through the player.
    final crease = _stroke(surface, 2);
    if (sideOn) {
      canvas.drawLine(
        Offset(player.dx, pitch.top),
        Offset(player.dx, pitch.bottom),
        crease,
      );
    } else {
      canvas.drawLine(
        Offset(pitch.left, player.dy),
        Offset(pitch.right, player.dy),
        crease,
      );
    }

    _dashed(canvas, camera, player, _stroke(accent, 2));
    canvas.drawCircle(player, 9, Paint()..color = ink);
    final towardsPlayer = (player - camera).direction;
    _phone(canvas, camera, 34, turn: towardsPlayer);

    final mid = Offset.lerp(camera, player, 0.5)!;
    _text(
      canvas,
      tour.distance,
      mid + Offset(w * 0.13, 0),
      color: accent,
    );
    _text(
      canvas,
      'Player',
      player + (sideOn ? Offset(-w * 0.1, 0) : Offset(0, -h * 0.1)),
    );
    _text(
      canvas,
      'Camera, ${tour.view.label.toLowerCase()}',
      sideOn ? Offset(w * 0.25, h * 0.82) : Offset(w * 0.68, camera.dy),
      color: muted,
    );
  }

  /// The phone screen with the whole player inside it.
  void _framing(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final frame = Rect.fromCenter(
      center: Offset(w * 0.42, h * 0.5),
      width: w * 0.62,
      height: h * 0.72,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(12)),
      Paint()..color = surface,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(12)),
      _stroke(ink, 3),
    );
    final feet = Offset(frame.center.dx, frame.bottom - frame.height * 0.14);
    final height = frame.height * 0.62;
    final guide = _stroke(accent, 2);
    _dashed(
      canvas,
      Offset(frame.left + 10, feet.dy),
      Offset(frame.right - 10, feet.dy),
      guide,
    );
    _dashed(
      canvas,
      Offset(frame.left + 10, feet.dy - height),
      Offset(frame.right - 10, feet.dy - height),
      guide,
    );
    _figure(canvas, feet, height);
    _text(canvas, 'Head', Offset(frame.right + w * 0.13, feet.dy - height),
        color: accent);
    _text(canvas, 'Feet', Offset(frame.right + w * 0.13, feet.dy),
        color: accent);
    _text(
      canvas,
      tour.height,
      Offset(frame.right + w * 0.13, frame.center.dy),
      color: muted,
      maxWidth: w * 0.24,
    );
  }

  /// The moments the clip has to contain, in order, with the ball marking
  /// the one that matters most.
  void _moments(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final moments = tour.moments;
    final left = w * 0.14;
    final right = w * 0.86;
    final y = h * 0.46;
    canvas.drawLine(Offset(left, y), Offset(right, y), _stroke(muted, 3));
    // Record from before the first moment until after the last.
    _text(canvas, 'Start', Offset(left, y - h * 0.2), color: muted);
    _text(canvas, 'Stop', Offset(right, y - h * 0.2), color: muted);
    canvas.drawCircle(Offset(left, y), 6, Paint()..color = muted);
    canvas.drawCircle(Offset(right, y), 6, Paint()..color = muted);

    // The middle moment is the one the measurements centre on.
    final key = moments.length ~/ 2;
    for (var i = 0; i < moments.length; i++) {
      final x = left + (right - left) * (i + 1) / (moments.length + 1);
      final centre = Offset(x, y);
      if (i == key) {
        BallPainter.paintBall(canvas, centre, 11, ball, seam);
      } else {
        canvas.drawCircle(centre, 8, Paint()..color = accent);
      }
      _text(
        canvas,
        moments[i],
        Offset(x, y + h * 0.2),
        maxWidth: (right - left) / (moments.length + 1) * 0.95,
      );
    }
  }

  /// A phone propped on a stand with the light behind it.
  void _steady(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ground = h * 0.82;
    canvas.drawLine(
      Offset(w * 0.08, ground),
      Offset(w * 0.92, ground),
      _stroke(muted, 2),
    );
    // Sun behind the camera.
    final sun = Offset(w * 0.16, h * 0.24);
    canvas.drawCircle(sun, h * 0.08, Paint()..color = AppColors.pitchStraw);
    final ray = _stroke(AppColors.pitchStraw, 3);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        sun + direction * h * 0.11,
        sun + direction * h * 0.15,
        ray,
      );
    }
    // Tripod.
    final top = Offset(w * 0.36, h * 0.5);
    final leg = _stroke(ink, 3);
    canvas.drawLine(top, Offset(w * 0.30, ground), leg);
    canvas.drawLine(top, Offset(w * 0.42, ground), leg);
    canvas.drawLine(top, Offset(w * 0.36, ground), leg);
    _phone(canvas, top - Offset(0, h * 0.07), w * 0.13);
    // Player in the light.
    _dashed(
      canvas,
      top + Offset(w * 0.09, -h * 0.07),
      Offset(w * 0.66, h * 0.5),
      _stroke(accent, 2),
    );
    _figure(canvas, Offset(w * 0.74, ground), h * 0.5);
  }

  /// A large tick in a circle.
  void _checklist(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.height * 0.28;
    canvas.drawCircle(centre, radius, Paint()..color = accent);
    final tick = Path()
      ..moveTo(centre.dx - radius * 0.45, centre.dy + radius * 0.02)
      ..lineTo(centre.dx - radius * 0.1, centre.dy + radius * 0.36)
      ..lineTo(centre.dx + radius * 0.48, centre.dy - radius * 0.32);
    canvas.drawPath(tick, _stroke(surface, radius * 0.16));
  }

  @override
  bool shouldRepaint(_TourPainter oldDelegate) =>
      oldDelegate.tour != tour ||
      oldDelegate.diagram != diagram ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent;
}
