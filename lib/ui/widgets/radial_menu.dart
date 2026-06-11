import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cubix_blast/core/audio_service.dart';

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

class RadialModeMenu extends StatefulWidget {
  final List<RadialMenuItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onRandomPressed;

  const RadialModeMenu({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onRandomPressed,
  });

  @override
  State<RadialModeMenu> createState() => _RadialModeMenuState();
}

class _RadialModeMenuState extends State<RadialModeMenu> {
  double _accumulatedDelta = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final centerOffset = height * 0.15; // padding a la izquierda para el botón central
        final width = height * 0.65 + centerOffset;

        final sweepAngle = math.pi / widget.items.length; // 180 grados / n
        // Calculamos la rotación necesaria para que el ítem seleccionado esté en 0 radianes
        final targetRotation = (math.pi / 2) - ((widget.selectedIndex + 0.5) * sweepAngle);

        return TweenAnimationBuilder<double>(
          tween: Tween(
            begin: targetRotation - (math.pi * 1.5), // Animación inicial (giro largo)
            end: targetRotation
          ),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutQuart,
          builder: (context, rotation, child) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                final center = Offset(centerOffset, height / 2);
                final dx = details.localPosition.dx - center.dx;
                final dy = details.localPosition.dy - center.dy;
                final distance = math.sqrt(dx * dx + dy * dy);

                // Check for random button tap (núcleo)
                if (distance < height * 0.16) {
                  widget.onRandomPressed();
                  return;
                }

                final outerRadius = height * 0.45;

                // Cualquier tap fuera del núcleo pero dentro de la rueda gigante
                if (distance > (outerRadius + 80)) return;

                // Vemos a qué rebanada corresponde basándonos en el ángulo en pantalla
                double screenAngle = math.atan2(dy, dx);
                
                // Permitimos MUCHO margen (0.4 rad) en los bordes para facilitar el tap en la mitad derecha visible
                if (screenAngle < (-math.pi / 2 - 0.4) || screenAngle > (math.pi / 2 + 0.4)) return;

                // Calculamos el índice absoluto basado en la rotación total
                double rawAngle = screenAngle - rotation;
                int absoluteIndex = ((rawAngle + math.pi / 2) / sweepAngle).floor();

                widget.onSelected(absoluteIndex);
              },
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // El menú giratorio
                    Positioned(
                      left: centerOffset,
                      top: 0,
                      bottom: 0,
                      width: width - centerOffset,
                      child: Transform.rotate(
                        angle: rotation,
                        alignment: Alignment.centerLeft,
                        child: CustomPaint(
                          size: Size(width - centerOffset, height),
                          painter: RadialMenuPainter(
                            items: widget.items,
                            selectedIndex: widget.selectedIndex,
                            rotationOffset: rotation,
                          ),
                        ),
                      ),
                    ),
                    // Cubo/Núcleo central interactivo (Botón Random)
                    Positioned(
                      left: 0,
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
                          Icons.shuffle,
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
    final outerRadius = size.height * 0.45;
    final innerRadius = outerRadius * 0.35; // Más cerca al centro
    
    final sweepAngle = math.pi / items.length;
    final startOffset = -math.pi / 2;

    final totalItems = items.length;
    final int selectedModIndex = selectedIndex % totalItems;
    final int realSelectedMod = selectedModIndex < 0 ? selectedModIndex + totalItems : selectedModIndex;

    final int startI = selectedIndex - totalItems;
    final int endI = selectedIndex + totalItems;

    // Primer paso: Dibujar TODOS los botones NO seleccionados
    for (int i = startI; i <= endI; i++) {
      int actualIndex = i % totalItems;
      if (actualIndex < 0) actualIndex += totalItems;
      
      if (actualIndex == realSelectedMod) continue; // Saltamos los seleccionados

      _drawSingleItem(canvas, center, outerRadius, innerRadius, startOffset, sweepAngle, i, actualIndex, false);
    }

    // Segundo paso: Dibujar TODOS los botones seleccionados (sus clones) por encima
    // para que su sombra neon se superponga y no sea opacada por los inactivos.
    for (int i = startI; i <= endI; i++) {
      int actualIndex = i % totalItems;
      if (actualIndex < 0) actualIndex += totalItems;
      
      if (actualIndex != realSelectedMod) continue; // Saltamos los no seleccionados

      _drawSingleItem(canvas, center, outerRadius, innerRadius, startOffset, sweepAngle, i, actualIndex, true);
    }
  }

  void _drawSingleItem(Canvas canvas, Offset center, double outerRadius, double innerRadius, double startOffset, double sweepAngle, int i, int actualIndex, bool isSelected) {
    final item = items[actualIndex];
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
        isSelected ? item.highlightColor : item.baseColor.withValues(alpha: 0.6),
        const Color(0xFF060A14),
      ],
    );

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: currentOuterRadius));

    if (isSelected) {
      canvas.drawShadow(path, item.highlightColor, 20, true);
    } else {
      canvas.drawShadow(path, Colors.black, 10, true);
    }

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 1.5
      ..color = isSelected ? item.highlightColor : item.baseColor.withValues(alpha: 0.5);
    canvas.drawPath(path, borderPaint);

    _drawItemContent(canvas, center, currentOuterRadius, innerRadius, currentStart, sweepAngle, item, isSelected);
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
