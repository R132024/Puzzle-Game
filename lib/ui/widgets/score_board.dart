import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/game_engine.dart';
import '../theme/app_theme.dart';
import '../../core/score_manager.dart';
import 'dart:ui';

/// Displays score, level, and lines cleared in a glowing side panel.
class ScoreBoard extends StatelessWidget {
  const ScoreBoard({super.key, required this.state, required this.highScore});

  final GameState state;
  final int highScore;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1420).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(label: 'BEST', value: highScore.toString()),
              _StatItem(label: 'SCORE', value: state.score.toString()),
              _StatItem(label: 'LVL', value: state.level.toString()),
              _StatItem(label: 'LINES', value: state.linesCleared.toString()),
              ValueListenableBuilder<int>(
                valueListenable: ScoreManager.coinsNotifier,
                builder: (context, coins, child) {
                  return _StatItem(
                    label: 'COINS',
                    value: coins.toString(),
                    valueColor: Colors.amber,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final numValue = int.tryParse(value) ?? 0;
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 10,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: numValue),
          duration: const Duration(milliseconds: 300),
          builder: (context, val, child) {
            return Text(
              val.toString(),
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.white,
                shadows: [
                  Shadow(
                    color: (valueColor ?? const Color(0xFF00E5FF)).withValues(
                      alpha: 0.8,
                    ),
                    blurRadius: 10,
                  ),
                  Shadow(
                    color: (valueColor ?? const Color(0xFF00E5FF)).withValues(
                      alpha: 0.4,
                    ),
                    blurRadius: 20,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
