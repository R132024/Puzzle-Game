import 'package:flutter/material.dart';
import 'package:cubix_blast/core/i18n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:cubix_blast/theme/game_themes.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  void _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleController.instance.localeNotifier,
      builder: (context, locale, _) {
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final themes = GameThemes.themes.values.toList();
    final coins = ScoreManager.coins;

    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('theme_shop'),
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '🪙 $coins',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final theme = themes[index];
          final isUnlocked = ScoreManager.unlockedThemes.contains(theme.id);
          final isSelected = ScoreManager.currentTheme == theme.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF1E293B),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                _buildPalettePreview(theme),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isSelected)
                        Text(
                          context.t('selected'),
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (isUnlocked)
                        const Text(
                          'UNLOCKED',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          '🪙 ${theme.price}',
                          style: const TextStyle(
                            color: Color(0xFFFFD600),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isSelected)
                  ElevatedButton(
                    onPressed: () async {
                      if (isUnlocked) {
                        await ScoreManager.setCurrentTheme(theme.id);
                        _update();
                      } else if (coins >= theme.price) {
                        final success = await ScoreManager.spendCoins(
                          theme.price,
                        );
                        if (success) {
                          await ScoreManager.unlockTheme(theme.id);
                          await ScoreManager.setCurrentTheme(theme.id);
                          _update();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUnlocked
                          ? const Color(0xFF2979FF)
                          : (coins >= theme.price
                                ? const Color(0xFFFFD600)
                                : Colors.grey),
                      foregroundColor: isUnlocked ? Colors.white : Colors.black,
                    ),
                    child: Text(isUnlocked ? context.t('select') : context.t('buy')),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPalettePreview(ThemePalette theme) {
    return Row(
      children: theme.pieceColors.take(4).map((color) {
        return Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }
}
