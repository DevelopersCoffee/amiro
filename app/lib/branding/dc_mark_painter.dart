
import 'package:flutter/rendering.dart';

import '../theme/amiro_theme.dart';

/// Brass line-art cup with two steam curls, drawn in a 120x120 box.
/// Flat strokes only: no glow, no gradient (DESIGN.md).
class DcMarkPainter extends CustomPainter {
  /// 0..1 progress of the cup outline trace.
  final double cup;

  /// 0..1 progress of each steam curl (draws up, then fades).
  final double steamA;
  final double steamB;

  const DcMarkPainter({
    required this.cup,
    required this.steamA,
    required this.steamB,
  });

  static const _box = 120.0;

  static final Path _cupPath = Path()
    ..moveTo(16, 50)
    ..lineTo(92, 50)
    ..lineTo(92, 78)
    ..quadraticBezierTo(92, 98, 72, 98)
    ..lineTo(36, 98)
    ..quadraticBezierTo(16, 98, 16, 78)
    ..close()
    ..moveTo(92, 58)
    ..cubicTo(112, 56, 112, 84, 90, 84)
    ..moveTo(28, 108)
    ..lineTo(80, 108);

  static final Path _steam1 = Path()
    ..moveTo(40, 40)
    ..cubicTo(32, 32, 48, 26, 40, 16)
    ..cubicTo(36, 11, 40, 7, 42, 4);

  static final Path _steam2 = Path()
    ..moveTo(62, 40)
    ..cubicTo(54, 32, 70, 26, 62, 16)
    ..cubicTo(58, 11, 62, 7, 64, 4);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _box;
    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AmiroColors.primary;

    _drawTrimmed(canvas, _cupPath, cup, stroke);
    _drawSteam(canvas, _steam1, steamA, stroke);
    _drawSteam(canvas, _steam2, steamB, stroke);
    canvas.restore();
  }

  /// Steam draws up over the first 70% of its progress, then fades out.
  void _drawSteam(Canvas canvas, Path path, double t, Paint stroke) {
    if (t <= 0) return;
    final draw = (t / 0.7).clamp(0.0, 1.0);
    final fade = t <= 0.7 ? 1.0 : 1.0 - (t - 0.7) / 0.3;
    final paint = Paint()
      ..style = stroke.style
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = stroke.strokeCap
      ..color = stroke.color.withValues(alpha: fade.clamp(0.0, 1.0));
    _drawTrimmed(canvas, path, draw, paint);
  }

  void _drawTrimmed(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(DcMarkPainter old) =>
      old.cup != cup || old.steamA != steamA || old.steamB != steamB;
}
