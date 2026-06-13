import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/i18n.dart';
import '../../core/audio_service.dart';
import '../logic/p2p_game_manager.dart';

/// Pantalla de la partida Online 1v1.
///
/// Esqueleto funcional: recibe el [P2PGameManager] ya conectado, escucha los
/// eventos del rival por el DataChannel y permite enviar ataques. Aquí es donde
/// integrarías tu `ClassicEngine` para el tablero real; los enganches de red ya
/// están listos (`enviarLineaBasura`, `onGameEvent`).
class OnlineMatchScreen extends StatefulWidget {
  const OnlineMatchScreen({super.key, required this.manager});
  final P2PGameManager manager;

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen> {
  int _incomingGarbage = 0;
  int _rivalScore = 0;
  bool _finished = false;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    widget.manager.onGameEvent = _handleEvent;
    widget.manager.onRivalLeft = _handleRivalLeft;
  }

  void _handleEvent(Map<String, dynamic> e) {
    if (!mounted) return;
    switch (e['t']) {
      case 'garbage':
        setState(() => _incomingGarbage += (e['lines'] as num?)?.toInt() ?? 0);
        break;
      case 'board':
        setState(() => _rivalScore = (e['score'] as num?)?.toInt() ?? 0);
        break;
      case 'gameover':
        // El rival perdió -> tú ganas.
        setState(() {
          _finished = true;
          _won = true;
        });
        break;
    }
  }

  void _handleRivalLeft() {
    if (!mounted || _finished) return;
    setState(() {
      _finished = true;
      _won = true;
    });
  }

  @override
  void dispose() {
    widget.manager.terminarPartida();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    context.t('connected'),
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF00E676),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const Spacer(),
              if (_finished) ...[
                Text(
                  _won ? context.t('you_win') : context.t('you_lose'),
                  style: GoogleFonts.orbitron(
                    color: _won
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF1744),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Text(
                  'RIVAL  ${_rivalScore.toString().padLeft(6, '0')}',
                  style: GoogleFonts.orbitron(
                      color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  '+$_incomingGarbage',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFFFF5500),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'líneas basura recibidas',
                  style: GoogleFonts.orbitron(
                      color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 32),
                // Demo: enviar un ataque al rival.
                ElevatedButton.icon(
                  onPressed: () {
                    AudioService.instance.playBoton();
                    widget.manager.enviarLineaBasura(2);
                  },
                  icon: const Icon(Icons.bolt),
                  label: const Text('Enviar 2 líneas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD500F9),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
