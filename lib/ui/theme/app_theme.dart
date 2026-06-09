import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CubixBlast Material 3 theme.
///
/// Neon-cyber dark palette with vibrant accents.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF00E5FF);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF0A0E1A),
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF060A14),
      textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF121828),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // ─── Game-specific colors ───────────────────────────────────

  static const Color gridBackground = Color(
    0xAA060A14,
  ); // Semi-transparent for visualizer
  static const gridLine = Color(0xFF1A2332);
  static const ghostColor = Color(0x40FFFFFF);
  static const uiGlow = Color(0xFF00E5FF);
}
