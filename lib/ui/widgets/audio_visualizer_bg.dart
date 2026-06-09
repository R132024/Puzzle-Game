import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nowplaying/nowplaying_track.dart';
import 'package:cubix_blast/core/music_service.dart';
import 'particles_bg.dart';

/// A simulated audio visualizer background with animated bars.
class AudioVisualizerBg extends StatefulWidget {
  const AudioVisualizerBg({
    super.key,
    required this.color,
    this.tempoMultiplier = 1.0,
  });

  final Color color;
  final double tempoMultiplier;

  @override
  State<AudioVisualizerBg> createState() => _AudioVisualizerBgState();
}

class _AudioVisualizerBgState extends State<AudioVisualizerBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Repeating animation to drive the visualizer
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
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
        return ValueListenableBuilder<NowPlayingTrack?>(
          valueListenable: MusicService.instance.currentTrack,
          builder: (context, track, _) {
            // Ask package to resolve the image if it's missing (usually happens async)
            if (track != null && !track.hasImage && track.imageNeedsResolving && !track.isResolvingImage) {
              track.resolveImage().then((_) {
                if (mounted) setState(() {});
              });
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                if (track != null && track.hasImage)
                  Positioned.fill(
                    child: Image(
                      image: track.image!,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.7),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                ParticlesBg(
                  color: widget.color,
                  speedMultiplier: widget.tempoMultiplier,
                ),
                CustomPaint(
                  painter: _VisualizerPainter(
                    time: _controller.value * 2 * pi * 10 * widget.tempoMultiplier,
                    baseColor: widget.color,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  _VisualizerPainter({
    required this.time,
    required this.baseColor,
  });

  final double time;
  final Color baseColor;

  static const int barCount = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / barCount;
    final maxBarHeight = size.height * 0.4; // Max height is 40% of screen height
    
    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // We generate pseudo-random heights using sine waves
    for (int i = 0; i < barCount; i++) {
      // Create a complex wave for each bar using its index and time
      final wave1 = sin(time * 0.5 + i * 0.2);
      final wave2 = sin(time * 0.8 - i * 0.5);
      final wave3 = cos(time * 1.2 + i * 0.1);
      
      // Combine waves and map to [0, 1] range roughly
      double heightFactor = (wave1 + wave2 + wave3) / 3.0;
      heightFactor = (heightFactor.abs() * 1.2).clamp(0.05, 1.0);

      // Random jitter
      final jitter = (sin(time * 5 + i * 13) * 0.1).abs();
      heightFactor = (heightFactor + jitter).clamp(0.05, 1.0);

      final currentHeight = maxBarHeight * heightFactor;
      
      // Draw bars emerging from the bottom
      final rect = Rect.fromLTWH(
        i * barWidth,
        size.height - currentHeight,
        barWidth - 2, // 2px gap between bars
        currentHeight,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) => true;
}
