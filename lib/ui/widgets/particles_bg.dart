import 'dart:math';
import 'package:flutter/material.dart';

class ParticlesBg extends StatefulWidget {
  const ParticlesBg({super.key, required this.color, required this.speedMultiplier});
  final Color color;
  final double speedMultiplier;

  @override
  State<ParticlesBg> createState() => _ParticlesBgState();
}

class _ParticlesBgState extends State<ParticlesBg> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < 50; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: _random.nextDouble() * 0.5 + 0.1,
        size: _random.nextDouble() * 3 + 1,
        alpha: _random.nextDouble() * 0.5 + 0.1,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            particles: _particles,
            time: _controller.value,
            color: widget.color,
            speedMultiplier: widget.speedMultiplier,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.alpha,
  });
  final double x;
  double y;
  final double speed;
  final double size;
  final double alpha;
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({
    required this.particles,
    required this.time,
    required this.color,
    required this.speedMultiplier,
  });

  final List<_Particle> particles;
  final double time;
  final Color color;
  final double speedMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final p in particles) {
      // Y moves upwards based on time and speed
      // We use time but we want continuous movement, so we just calculate position based on modulo
      // Wait, time goes from 0 to 1 repeatedly. This might cause jumping.
      // A better way is to update particle Y in the painter, but CustomPainters shouldn't mutate state.
      // So we map time to distance. 
      // Distance = (time * speed * speedMultiplier) % 1.0;
      // Actually, since speedMultiplier can change, modulo might skip.
      
      // We can just use the animation value to smoothly shift them.
      // 1.0 represents one full cycle. 
      // If we want continuous scrolling upwards:
      final yOffset = (time * p.speed * speedMultiplier * 10) % 1.0;
      double currentY = p.y - yOffset;
      if (currentY < 0) currentY += 1.0;

      paint.color = color.withValues(alpha: p.alpha);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(p.x * size.width, currentY * size.height),
          width: p.size,
          height: p.size,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
