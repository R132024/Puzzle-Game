import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';
import 'classic/ui/classic_screen.dart';
import 'arena/ui/arena_screen.dart';
import 'power/ui/power_screen.dart';
import 'ui/screens/shop_screen.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:cubix_blast/core/music_service.dart';
import 'package:cubix_blast/multiplayer/ui/multiplayer_lobby_screen.dart';
import 'package:cubix_blast/multiplayer/ui/multiplayer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await ScoreManager.init();
  MusicService.instance.init(); // non-blocking request

  runApp(const ProviderScope(child: CubixBlastApp()));
}

class CubixBlastApp extends StatelessWidget {
  const CubixBlastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CubixBlast: Puzzle Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/classic': (_) => const ClassicScreen(),
        '/arena': (_) => const ArenaScreen(),
        '/power': (_) => const PowerScreen(),
        '/multiplayer_lobby': (_) => const MultiplayerLobbyScreen(),
        '/multiplayer_match': (_) => const MultiplayerScreen(),
        '/shop': (_) => const ShopScreen(),
      },
    );
  }
}
