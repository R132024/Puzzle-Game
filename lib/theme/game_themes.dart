import 'package:flutter/material.dart';

class ThemePalette {
  const ThemePalette({
    required this.id,
    required this.name,
    required this.price,
    required this.backgroundColors,
    required this.pieceColors,
  });

  final String id;
  final String name;
  final int price;
  final List<Color> backgroundColors;
  final List<Color> pieceColors;
}

class GameThemes {
  static const classicId = 'classic';
  static const vaporwaveId = 'vaporwave';
  static const matrixId = 'matrix';
  static const monochromeId = 'monochrome';

  static final Map<String, ThemePalette> themes = {
    classicId: const ThemePalette(
      id: classicId,
      name: 'Classic Neon',
      price: 0,
      backgroundColors: [
        Color(0xFF00E5FF),
        Color(0xFFFFD600),
        Color(0xFFAA00FF),
        Color(0xFF00E676),
        Color(0xFFFF1744),
      ],
      pieceColors: [
        Color(0xFF00E5FF), // I - Cyan (sin cambios, no especificada)
        Color(0xFFEEDDBC), // O - Cuadrado crema
        Color(0xFF7700EE), // T - Morada
        Color(0xFF00AA77), // S - Verde
        Color(0xFF990066), // Z - Fucsia
        Color(0xFF0077AA), // J - Azul/turquesa
        Color(0xFFFF5500), // L - Naranja
      ],
    ),
    vaporwaveId: const ThemePalette(
      id: vaporwaveId,
      name: 'Vaporwave',
      price: 500,
      backgroundColors: [
        Color(0xFFFF00FF), // Magenta
        Color(0xFF00FFFF), // Cyan
        Color(0xFF8A2BE2), // Blue Violet
        Color(0xFFFF1493), // Deep Pink
        Color(0xFF00CED1), // Dark Turquoise
      ],
      pieceColors: [
        Color(0xFF00FFFF),
        Color(0xFFFF00FF),
        Color(0xFF8A2BE2),
        Color(0xFFFF1493),
        Color(0xFF00CED1),
        Color(0xFF9370DB),
        Color(0xFFFF69B4),
      ],
    ),
    matrixId: const ThemePalette(
      id: matrixId,
      name: 'Matrix Hacker',
      price: 1000,
      backgroundColors: [
        Color(0xFF00FF00),
        Color(0xFF32CD32),
        Color(0xFF00FA9A),
        Color(0xFF00FF7F),
        Color(0xFF228B22),
      ],
      pieceColors: [
        Color(0xFF00FF00),
        Color(0xFF32CD32),
        Color(0xFF00FA9A),
        Color(0xFF00FF7F),
        Color(0xFF7CFC00),
        Color(0xFFADFF2F),
        Color(0xFF2E8B57),
      ],
    ),
    monochromeId: const ThemePalette(
      id: monochromeId,
      name: 'Monochrome',
      price: 1500,
      backgroundColors: [
        Color(0xFFFFFFFF),
        Color(0xFFCCCCCC),
        Color(0xFF999999),
        Color(0xFF666666),
        Color(0xFF333333),
      ],
      pieceColors: [
        Color(0xFFFFFFFF),
        Color(0xFFEEEEEE),
        Color(0xFFDDDDDD),
        Color(0xFFCCCCCC),
        Color(0xFFBBBBBB),
        Color(0xFFAAAAAA),
        Color(0xFF999999),
      ],
    ),
  };

  static ThemePalette getTheme(String id) {
    return themes[id] ?? themes[classicId]!;
  }
}
