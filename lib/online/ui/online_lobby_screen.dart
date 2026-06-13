import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/i18n.dart';
import '../../core/audio_service.dart';
import '../logic/p2p_game_manager.dart';
import '../logic/online_invite.dart';
import 'online_match_screen.dart';

/// Lobby del modo Online 1v1 (Firebase signaling + WebRTC).
class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key, this.autoJoinRoom});

  /// Si viene de un deep link de WhatsApp, se une automáticamente.
  final String? autoJoinRoom;

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final P2PGameManager _mgr = P2PGameManager();
  final TextEditingController _codeCtrl = TextEditingController();
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _mgr.status.addListener(_onStatusChange);

    // Auto-join si llegamos por invitación.
    final auto = widget.autoJoinRoom;
    if (auto != null && auto.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mgr.unirseAPartida(auto);
      });
    }
  }

  void _onStatusChange() {
    if (!mounted) return;
    setState(() {});
    if (_mgr.status.value == P2PStatus.connected && !_navigated) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnlineMatchScreen(manager: _mgr),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mgr.status.removeListener(_onStatusChange);
    _codeCtrl.dispose();
    // Si NO navegamos a la partida, limpiamos la sala aquí.
    if (!_navigated) _mgr.terminarPartida();
    super.dispose();
  }

  Future<void> _crear() async {
    AudioService.instance.playBoton();
    final roomId = await _mgr.crearPartida();
    if (roomId != null && mounted) {
      await OnlineInvite.compartir(context, roomId);
    }
  }

  Future<void> _unirse() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    AudioService.instance.playBoton();
    await _mgr.unirseAPartida(code);
  }

  @override
  Widget build(BuildContext context) {
    final st = _mgr.status.value;
    final busy = st == P2PStatus.waitingRival ||
        st == P2PStatus.connecting ||
        st == P2PStatus.joining ||
        st == P2PStatus.creating;

    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          context.t('title_online'),
          style: GoogleFonts.orbitron(
            color: const Color(0xFFD500F9),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public, color: Color(0xFFD500F9), size: 72),
                const SizedBox(height: 24),

                if (busy) ...[
                  const CircularProgressIndicator(color: Color(0xFFD500F9)),
                  const SizedBox(height: 16),
                  Text(
                    st == P2PStatus.waitingRival
                        ? context.t('waiting_rival')
                        : context.t('connecting'),
                    style: GoogleFonts.orbitron(color: Colors.white70),
                  ),
                  if (st == P2PStatus.waitingRival && _mgr.roomId != null) ...[
                    const SizedBox(height: 24),
                    _roomCodeBox(_mgr.roomId!),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          OnlineInvite.compartir(context, _mgr.roomId!),
                      icon: const Icon(Icons.share),
                      label: Text(context.t('invite_whatsapp')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ] else if (st == P2PStatus.error) ...[
                  Text(
                    _mgr.errorMessage.value ?? 'Error',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(color: const Color(0xFFFF1744)),
                  ),
                ] else ...[
                  // Crear partida
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _crear,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(context.t('create_match')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD500F9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.t('enter_room_code'),
                    style: GoogleFonts.orbitron(
                        color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeCtrl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: context.t('room_code'),
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _unirse,
                      icon: const Icon(Icons.login, color: Color(0xFFD500F9)),
                      label: Text(context.t('join_match')),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD500F9)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roomCodeBox(String code) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        AudioService.instance.playBoton();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD500F9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.copy, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }
}
