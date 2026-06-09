import 'package:flutter/material.dart';

class BlockPainterUtils {
  /// Draws a glassmorphic/neon block inside a canvas.
  static void drawBlock({
    required Canvas canvas,
    required Rect rect,
    required Color color,
    bool isGhost = false,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    if (isGhost) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(rrect, paint);

      // Inner subtle fill for ghost
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, fillPaint);
    } else {
      // 1. Base glassy fill with neon gradient
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.5)],
        ).createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rrect, fillPaint);

      // 2. Bevel / Inner glass reflection (Top-Left bright, Bottom-Right dark)
      final highlightPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.5),
          ],
          stops: const [0.0, 0.4, 0.6, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawRRect(rrect, highlightPaint);
    }
  }
}
