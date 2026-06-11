import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cubix_blast/core/high_score_store.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:cubix_blast/core/audio_service.dart';
import 'package:cubix_blast/core/player_manager.dart';
import 'package:cubix_blast/core/mission_manager.dart';
import 'package:cubix_blast/ui/widgets/radial_menu.dart';

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
  int _startingLevel = 1;
  int _selectedModeIndex = 0;
  List<Map<String, dynamic>> _leaderboard = [];

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
    final scores = await HighScoreStore.getAllHighScores();
    if (mounted) {
      setState(() {
        _leaderboard = scores;
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
        title: ValueListenableBuilder<PlayerProfile>(
          valueListenable: PlayerManager.profileNotifier,
          builder: (context, profile, child) {
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${profile.level}',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NIVEL ${profile.level}',
                        style: GoogleFonts.orbitron(fontSize: 10, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: profile.progress,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFF00E5FF),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            );
          },
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: AudioService.instance.bgmNotifier,
            builder: (context, isEnabled, child) {
              return IconButton(
                icon: Icon(isEnabled ? Icons.music_note : Icons.music_off, color: Colors.white70),
                onPressed: () {
                  AudioService.instance.playBoton();
                  AudioService.instance.toggleBgm();
                },
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AudioService.instance.sfxNotifier,
            builder: (context, isEnabled, child) {
              return IconButton(
                icon: Icon(isEnabled ? Icons.volume_up : Icons.volume_off, color: Colors.white70),
                onPressed: () {
                  AudioService.instance.playBoton();
                  AudioService.instance.toggleSfx();
                },
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: ScoreManager.coinsNotifier,
            builder: (context, coins, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 20,
                    ),
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
                child: _showModes
                    ? _buildModeSelection()
                    : _buildInitialBanner(),
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
        const SizedBox(height: 40),
        _buildMissionsPanel(),
        const SizedBox(height: 40),
        _buildLeaderboardTable(),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            AudioService.instance.playBoton();
            setState(() {
              _showModes = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
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
            AudioService.instance.playBoton();
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

  String _translateMode(String mode) {
    switch (mode) {
      case 'classic':
        return 'Clásico';
      case 'arena':
        return 'Arena';
      case 'power':
        return 'Poderes';
      case 'multiplayer':
        return 'Multijugador';
      default:
        return mode;
    }
  }

  Widget _buildMissionsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'MISIONES DIARIAS',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<List<DailyMission>>(
            valueListenable: MissionManager.missionsNotifier,
            builder: (context, missions, child) {
              if (missions.isEmpty) return const SizedBox.shrink();
              return Column(
                children: missions.map((mission) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                mission.title,
                                style: TextStyle(
                                  color: mission.isCompleted ? Colors.white54 : Colors.white,
                                  decoration: mission.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            Text(
                              '${mission.current} / ${mission.target}',
                              style: TextStyle(
                                color: mission.isCompleted ? const Color(0xFF00E676) : const Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: mission.progress,
                          backgroundColor: Colors.white12,
                          color: mission.isCompleted ? const Color(0xFF00E676) : const Color(0xFF00E5FF),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'TABLA DE PUNTUACIONES',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_leaderboard.isEmpty)
            Center(
              child: Text(
                'Aún no hay puntuaciones',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
            )
          else ...[
            // Header
            Row(
              children: [
                Expanded(flex: 2, child: _buildTableHeader('Nombre')),
                Expanded(flex: 3, child: _buildTableHeader('Tipo de juego')),
                Expanded(flex: 2, child: _buildTableHeader('Nivel')),
                Expanded(
                  flex: 3,
                  child: _buildTableHeader('Puntuación', alignRight: true),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            // Rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _leaderboard.length,
              itemBuilder: (context, index) {
                final record = _leaderboard[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          record['name'] ?? '----',
                          style: GoogleFonts.orbitron(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _translateMode(record['mode'] ?? ''),
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            color: const Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${record['level'] ?? 1}',
                          style: GoogleFonts.orbitron(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${record['score'] ?? 0}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00E676),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title, {bool alignRight = false}) {
    return Text(
      title,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: GoogleFonts.orbitron(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white54,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildModeSelection() {
    return SizedBox(
      height: 500, // Altura fija para el área de selección
      child: Row(
        children: [
          // Mitad Izquierda: Menú Radial
          Expanded(
            flex: 4,
            child: Transform.translate(
              offset: const Offset(-32, 0), // Pegado al borde
              child: RadialModeMenu(
                selectedIndex: _selectedModeIndex,
                onSelected: (index) {
                  AudioService.instance.playBoton();
                  setState(() => _selectedModeIndex = index);
                },
                items: [
                  RadialMenuItem(
                    title: 'CLÁSICO',
                    icon: Icons.grid_on,
                    baseColor: const Color(0xFF00E5FF),
                    highlightColor: const Color(0xFF00B8D4),
                  ),
                  RadialMenuItem(
                    title: 'ARENA',
                    icon: Icons.timer,
                    baseColor: const Color(0xFFFF3D00),
                    highlightColor: const Color(0xFFDD2C00),
                  ),
                  RadialMenuItem(
                    title: 'PODERES',
                    icon: Icons.bolt,
                    baseColor: const Color(0xFFFFD600),
                    highlightColor: const Color(0xFFFFAB00),
                  ),
                  RadialMenuItem(
                    title: 'MULTI',
                    icon: Icons.wifi_tethering,
                    baseColor: const Color(0xFFD500F9),
                    highlightColor: const Color(0xFFAA00FF),
                  ),
                ],
              ),
            ),
          ),
          
          // Mitad Derecha: Panel de Detalles
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _buildRightPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    // Definimos información estática para cada modo
    final modesInfo = [
      {
        'title': 'MODO CLÁSICO',
        'desc': 'El rompecabezas original. Limpia líneas sin presión de tiempo.',
        'color': const Color(0xFF00E5FF),
        'route': '/classic',
      },
      {
        'title': 'MODO ARENA',
        'desc': '¡Compite contra el reloj! Gana puntos extra por combos rápidos.',
        'color': const Color(0xFFFF3D00),
        'route': '/arena',
      },
      {
        'title': 'CON PODERES',
        'desc': 'Usa habilidades especiales como Láser y Bomba para destruir bloques.',
        'color': const Color(0xFFFFD600),
        'route': '/power',
      },
      {
        'title': 'MULTIJUGADOR',
        'desc': 'Desafía a tus amigos en partidas locales y demuestra quién manda.',
        'color': const Color(0xFFD500F9),
        'route': '/multiplayer_lobby',
      },
    ];

    final info = modesInfo[_selectedModeIndex];
    final color = info['color'] as Color;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_selectedModeIndex),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              info['title'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 2,
                shadows: [Shadow(color: color, blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              info['desc'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                fontSize: 12,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Selector de Nivel
            if (_selectedModeIndex != 3) ...[
              Text(
                'NIVEL INICIAL',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                    onPressed: () {
                      if (_startingLevel > 1) {
                        AudioService.instance.playBoton();
                        setState(() => _startingLevel--);
                      }
                    },
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text(
                      '$_startingLevel',
                      style: GoogleFonts.orbitron(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    onPressed: () {
                      if (_startingLevel < 15) {
                        AudioService.instance.playBoton();
                        setState(() => _startingLevel++);
                      }
                    },
                  ),
                ],
              ),
            ] else ...[
               const SizedBox(height: 60), // Espacio para igualar la altura si no hay nivel
            ],
            
            const Spacer(),
            
            // Botón Jugar
            ElevatedButton(
              onPressed: () {
                AudioService.instance.playBoton();
                if (_selectedModeIndex == 3) {
                  Navigator.pushNamed(context, info['route'] as String);
                } else {
                  Navigator.pushNamed(context, info['route'] as String, arguments: {'initialLevel': _startingLevel}).then((_) => _loadRecords());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: color.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'JUGAR',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            // Botón Volver
            TextButton(
              onPressed: () {
                AudioService.instance.playBoton();
                setState(() => _showModes = false);
              },
              child: Text(
                'VOLVER AL INICIO',
                style: GoogleFonts.orbitron(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderMask(
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
              maxLines: 1,
              style: GoogleFonts.orbitron(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
        );
      },
    );
  }
}
