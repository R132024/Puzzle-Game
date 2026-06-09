import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cubix_blast/core/high_score_store.dart';
import 'package:cubix_blast/core/score_manager.dart';

/// Home screen with animated mode selection menu and high scores.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  bool _showModes = false;
  HighScore? _classicRecord;
  HighScore? _arenaRecord;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final classic = await HighScoreStore.getHighScore('classic');
    final arena = await HighScoreStore.getHighScore('arena');
    if (mounted) {
      setState(() {
        _classicRecord = classic;
        _arenaRecord = arena;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: ScoreManager.coinsNotifier,
            builder: (context, coins, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$coins',
                      style: GoogleFonts.orbitron(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _showModes ? _buildModeSelection() : _buildInitialBanner(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialBanner() {
    return Column(
      key: const ValueKey('banner'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTitle(),
        const SizedBox(height: 12),
        Text(
          'PUZZLE GAME',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            letterSpacing: 8,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 60),
        _buildRecordsBanner(),
        const SizedBox(height: 60),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showModes = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 8,
            shadowColor: const Color(0xFF00E5FF).withValues(alpha: 0.5),
          ),
          child: Text(
            'JUGAR',
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/shop').then((_) => _loadRecords());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: const Color(0xFFFFD600),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: Color(0xFFFFD600), width: 1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.palette, size: 20),
              const SizedBox(width: 12),
              Text(
                'THEME SHOP',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'MEJORES PUNTUACIONES',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRecordItem('CLÁSICO', _classicRecord, const Color(0xFF00E5FF)),
              Container(width: 1, height: 60, color: Colors.white24),
              _buildRecordItem('ARENA', _arenaRecord, const Color(0xFFAA00FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String mode, HighScore? record, Color color) {
    return Column(
      children: [
        Text(
          mode,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          record?.hasRecord == true ? '${record!.score}' : '0',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          record?.hasRecord == true ? record!.name : '----',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelection() {
    return Column(
      key: const ValueKey('modes'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SELECCIONA UN MODO',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            letterSpacing: 4,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 40),
        _buildModeCard(
          title: 'CLÁSICO',
          subtitle: 'Bloques que caen en rejilla 10×20.\nCompleta líneas para limpiar.',
          icon: Icons.grid_on,
          gradientColors: [
            const Color(0xFF00E5FF),
            const Color(0xFF2979FF),
          ],
          onTap: () => Navigator.pushNamed(context, '/classic').then((_) => _loadRecords()),
        ),
        const SizedBox(height: 20),
        _buildModeCard(
          title: 'ARENA',
          subtitle: 'Los bloques se desintegran en arena.\nConecta colores de pared a pared.',
          icon: Icons.grain,
          gradientColors: [
            const Color(0xFFAA00FF),
            const Color(0xFFFF1744),
          ],
          onTap: () => Navigator.pushNamed(context, '/arena').then((_) => _loadRecords()),
        ),
        const SizedBox(height: 20),
        _buildModeCard(
          title: 'PODERES',
          subtitle: 'Gasta monedas para usar poderes.\nBomba, cámara lenta y salvavidas.',
          icon: Icons.bolt,
          gradientColors: [
            const Color(0xFF00E676),
            const Color(0xFFFFD600),
          ],
          onTap: () => Navigator.pushNamed(context, '/power').then((_) => _loadRecords()),
        ),
        const SizedBox(height: 20),
        _buildModeCard(
          title: 'MULTIJUGADOR',
          subtitle: 'Conecta por Bluetooth o WiFi local.\n¡Envíale basura a tus amigos!',
          icon: Icons.wifi_tethering,
          gradientColors: [
            const Color(0xFF8E24AA),
            const Color(0xFFE040FB),
          ],
          onTap: () => Navigator.pushNamed(context, '/multiplayer_lobby'),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () {
            setState(() {
              _showModes = false;
            });
          },
          child: const Text('VOLVER AL INICIO', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              const Color(0xFF00E5FF),
              Color.lerp(
                const Color(0xFFAA00FF),
                const Color(0xFF00E5FF),
                _pulseAnim.value,
              )!,
              const Color(0xFFFF1744),
            ],
          ).createShader(bounds),
          child: Text(
            'CUBIXBLAST',
            style: GoogleFonts.orbitron(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: gradientColors.first.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.1 * _pulseAnim.value),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.orbitron(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 32,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
