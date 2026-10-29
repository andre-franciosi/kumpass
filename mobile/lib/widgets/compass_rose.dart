import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/kumpas_theme.dart';

/// Marca do Kumpas: uma bússola desenhada (também usada no ícone da app).
class CompassRose extends StatelessWidget {
  const CompassRose({
    super.key,
    this.size = 96,
    this.background = KumpasPalette.paper,
    this.showTicks = true,
  });

  final double size;
  final Color background;
  final bool showTicks;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CompassPainter(background: background, showTicks: showTicks),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter({required this.background, required this.showTicks});

  final Color background;
  final bool showTicks;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.075
      ..color = KumpasPalette.forest
      ..strokeCap = StrokeCap.round;

    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.035
      ..color = KumpasPalette.forestDark
      ..strokeCap = StrokeCap.round;

    // Fundo (para uso sobre imagens/gradientes).
    canvas.drawCircle(center, radius * 0.92, Paint()..color = background);

    // Anel exterior.
    canvas.drawCircle(center, radius * 0.9, ring);
    canvas.drawCircle(center, radius * 0.66, thin);

    // Marcações de 45°.
    if (showTicks) {
      for (var i = 0; i < 8; i++) {
        final angle = -math.pi / 2 + i * math.pi / 4;
        final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.86;
        final inner = center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.6;
        canvas.drawLine(inner, outer, thin);
      }
    }

    // Rosa dos ventos: 4 pontos principais + 4 secundários.
    _drawPoint(canvas, center, -math.pi / 2, radius * 0.58, radius * 0.16, KumpasPalette.amber);
    _drawPoint(canvas, center, math.pi / 2, radius * 0.5, radius * 0.14, KumpasPalette.ink);
    _drawPoint(canvas, center, 0, radius * 0.5, radius * 0.14, KumpasPalette.forest);
    _drawPoint(canvas, center, math.pi, radius * 0.5, radius * 0.14, KumpasPalette.forest);
    for (final angle in [
      -math.pi / 4,
      math.pi / 4,
      (3 * math.pi) / 4,
      -(3 * math.pi) / 4,
    ]) {
      _drawPoint(canvas, center, angle, radius * 0.32, radius * 0.1, KumpasPalette.muted);
    }

    // Pivô central.
    canvas.drawCircle(center, radius * 0.16, Paint()..color = background);
    canvas.drawCircle(center, radius * 0.16, thin);
    canvas.drawCircle(center, radius * 0.07, Paint()..color = KumpasPalette.amberDeep);
  }

  void _drawPoint(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    double halfWidth,
    Color color,
  ) {
    final direction = Offset(math.cos(angle), math.sin(angle));
    final perpendicular = Offset(-direction.dy, direction.dx);
    final tip = center + direction * length;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        center.dx + perpendicular.dx * halfWidth,
        center.dy + perpendicular.dy * halfWidth,
      )
      ..lineTo(center.dx, center.dy)
      ..lineTo(
        center.dx - perpendicular.dx * halfWidth,
        center.dy - perpendicular.dy * halfWidth,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.background != background || old.showTicks != showTicks;
}
