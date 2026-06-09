import 'package:shared_preferences/shared_preferences.dart';

/// Persists high scores and player names.
///
/// Uses shared_preferences.
class HighScoreStore {
  static const String _keyScorePrefix = 'highscore_score_';
  static const String _keyNamePrefix = 'highscore_name_';

  static Future<HighScore> getHighScore(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('$_keyScorePrefix$mode') ?? 0;
    final name = prefs.getString('$_keyNamePrefix$mode') ?? '----';
    return HighScore(score: score, name: name);
  }

  static Future<void> saveHighScore(String mode, int score, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyScorePrefix$mode', score);
    await prefs.setString('$_keyNamePrefix$mode', name);
  }
}

class HighScore {
  const HighScore({required this.score, required this.name});
  final int score;
  final String name;

  bool get hasRecord => score > 0;
}
