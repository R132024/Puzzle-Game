import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RadialMenuItem {
  final String title;
  final IconData icon;
  final Color baseColor;
  final Color highlightColor;

  RadialMenuItem({
    required this.title,
    required this.icon,
    required this.baseColor,
    required this.highlightColor,
  });
}

class RadialModeMenu extends StatelessWidget {
  final List<RadialMenuItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const RadialModeMenu({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = height / 2;

        final sweepAngle = math.pi / items.length; // 180 grados / n
        // Calculamos la rotación necesaria para que el ítem seleccionado esté en 0 radianes
        final targetRotation = (math.pi / 2) - ((selectedIndex + 0.5) * sweepAngle);

        return TweenAnimationBuilder<double>(
          tween: Tween(end: targetRotation),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, rotation, child) {
            return GestureDetector(
              onTapDown: (details) {
                final center = Offset(0, height / 2);
                final dx = details.localPosition.dx - center.dx;
                final dy = details.localPosition.dy - center.dy;
                final distance = math.sqrt(dx * dx + dy * dy);

                final outerRadius = height / 2;
                final innerRadius = outerRadius * 0.45;

                if (distance < innerRadius || distance > outerRadius) return;

                // Calculamos el ángulo compensando la rotación actual
                double angle = math.atan2(dy, dx) - rotation;

                // Normalizamos el ángulo entre -pi y pi
                while (angle <= -math.pi) angle += 2 * math.pi;
                while (angle > math.pi) angle -= 2 * math.pi;

                // Vemos a qué rebanada corresponde
                // El diseño base va de -pi/2 a pi/2
                if (angle < -math.pi / 2 || angle > math.pi / 2) return;

                double normalizedAngle = angle + (math.pi / 2);
                int index = (normalizedAngle / sweepAngle).floor();

                if (index >= 0 && index < items.length) {
                  onSelected(index);
                }
              },
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // El menú giratorio
                    Transform.rotate(
                      angle: rotation,
                      alignment: Alignment.centerLeft,
                      child: CustomPaint(
                        size: Size(width, height),
                        painter: RadialMenuPainter(
                          items: items,
                          selectedIndex: selectedIndex,
                          rotationOffset: rotation,
                        ),
                      ),
                    ),
                    // Cubo/Núcleo central estático
                    Positioned(
                      left: -height * 0.15,
                      top: height * 0.35,
                      child: Container(
                        width: height * 0.3,
                        height: height * 0.3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F172A),
                          border: Border.all(color: const Color(0xFF00E5FF), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFF060A14),
                              blurRadius: 20,
                              spreadRadius: -5,
                              blurStyle: BlurStyle.inner,
                            )
                          ],
                        ),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: height * 0.04),
                        child: Icon(
                          Icons.games,
                          color: const Color(0xFF00E5FF),
                          size: height * 0.08,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class RadialMenuPainter extends CustomPainter {
  final List<RadialMenuItem> items;
  final int selectedIndex;
  final double rotationOffset; // Usado para saber qué dibujar si queremos

  RadialMenuPainter({
    required this.items,
    required this.selectedIndex,
    required this.rotationOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(0, size.height / 2);
    final outerRadius = size.height / 2;
    final innerRadius = outerRadius * 0.45;
    
    final sweepAngle = math.pi / items.length;
    final startOffset = -math.pi / 2;

    for (int i = 0; i < items.length; i++) {
      final isSelected = i == selectedIndex;
      final currentStart = startOffset + (i * sweepAngle);
      
      final gap = 0.02;
      
      // Si está seleccionado, sobresale un poco
      final extraRadius = isSelected ? 20.0 : 0.0;
      final currentOuterRadius = outerRadius + extraRadius;

      final path = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: currentOuterRadius),
          currentStart + gap,
          sweepAngle - (gap * 2),
          true,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          currentStart + sweepAngle - gap,
          -(sweepAngle - (gap * 2)),
          false,
        )
        ..close();

      final gradient = RadialGradient(
        center: Alignment.centerLeft,
        radius: 1.0,
        colors: [
          isSelected ? items[i].highlightColor : items[i].baseColor.withValues(alpha: 0.6),
          const Color(0xFF060A14),
        ],
      );

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: currentOuterRadius));

      if (isSelected) {
        canvas.drawShadow(path, items[i].highlightColor, 20, true);
      } else {
        canvas.drawShadow(path, Colors.black, 10, true);
      }

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.5
        ..color = isSelected ? items[i].highlightColor : items[i].baseColor.withValues(alpha: 0.5);
      canvas.drawPath(path, borderPaint);

      _drawItemContent(canvas, center, currentOuterRadius, innerRadius, currentStart, sweepAngle, items[i], isSelected);
    }
  }

  void _drawItemContent(Canvas canvas, Offset center, double outerRadius, double innerRadius, double startAngle, double sweepAngle, RadialMenuItem item, bool isSelected) {
    final midAngle = startAngle + (sweepAngle / 2);
    final midRadius = innerRadius + ((outerRadius - innerRadius) / 2);

    final iconX = center.dx + midRadius * math.cos(midAngle);
    final iconY = center.dy + midRadius * math.sin(midAngle);

    canvas.save();
    canvas.translate(iconX, iconY);
    
    // Rotar para texto horizontal respecto a la pantalla global
    // Como el canvas está rotado por 'rotationOffset', lo contrarrestamos
    // Pero si queremos que apunte hacia afuera, usamos midAngle
    canvas.rotate(midAngle);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(item.icon.codePoint),
        style: TextStyle(
          fontSize: isSelected ? 34 : 28,
          fontFamily: item.icon.fontFamily,
          package: item.icon.fontPackage,
          color: isSelected ? Colors.white : Colors.white70,
          shadows: isSelected ? [Shadow(color: item.highlightColor, blurRadius: 15)] : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(-iconPainter.width / 2, -iconPainter.height / 2 - 10));

    final textPainter = TextPainter(
      text: TextSpan(
        text: item.title,
        style: GoogleFonts.orbitron(
          fontSize: isSelected ? 13 : 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? item.highlightColor : Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, iconPainter.height / 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RadialMenuPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.rotationOffset != rotationOffset;
  }
}
