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
      // 1. Base glassy fill (fast flat color)
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, fillPaint);

      // 2. Simple inner highlight (fast flat stroke) instead of complex 4-stop gradient
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(rrect, highlightPaint);
      
      // 3. Simple inner shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      // Draw shadow slightly offset
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.translate(1, 1),
          const Radius.circular(4),
        ),
        shadowPaint,
      );
    }
  }
}
