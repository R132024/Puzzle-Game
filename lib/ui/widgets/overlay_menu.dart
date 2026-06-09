import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';

class OverlayMenu extends StatelessWidget {
  const OverlayMenu({
    super.key,
    required this.title,
    required this.score,
    required this.bestScore,
    this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  final String title;
  final int score;
  final int bestScore;
  final VoidCallback? onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1420).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.uiGlow.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.uiGlow.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: AppTheme.uiGlow, blurRadius: 15)],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ScoreItem(label: 'SCORE', value: score),
                      const SizedBox(width: 40),
                      _ScoreItem(label: 'BEST', value: bestScore),
                    ],
                  ),
                  const SizedBox(height: 40),
                  if (onResume != null) ...[
                    _MenuButton(
                      label: 'RESUME',
                      icon: Icons.play_arrow,
                      onTap: onResume!,
                      color: const Color(0xFF00E676),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    _MenuButton(
                      label: 'SHARE SCORE',
                      icon: Icons.share,
                      onTap: () {
                        final text =
                            '🧊💥 He logrado $score pts en Cubix Blast! ¿Puedes vencerme? 🟦🟩🟪';
                        // ignore: deprecated_member_use
                        Share.share(text);
                      },
                      color: const Color(0xFFFFD600),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _MenuButton(
                    label: 'PLAY AGAIN',
                    icon: Icons.refresh,
                    onTap: onRestart,
                    color: const Color(0xFF00E5FF),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    label: 'MAIN MENU',
                    icon: Icons.home,
                    onTap: onHome,
                    color: const Color(0xFFFF1744),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  const _ScoreItem({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 12,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
