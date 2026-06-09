import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cubix_blast/power/logic/power_engine.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:cubix_blast/theme/game_themes.dart';
import 'package:cubix_blast/power/ui/power_painter.dart';
import 'package:cubix_blast/core/game_engine.dart';
import 'package:cubix_blast/ui/widgets/game_loop_widget.dart';
import 'package:cubix_blast/ui/widgets/score_board.dart';
import 'package:cubix_blast/ui/widgets/overlay_menu.dart';
import 'package:cubix_blast/ui/widgets/next_piece_preview.dart';

import 'package:cubix_blast/ui/widgets/game_gesture_detector.dart';
import 'package:cubix_blast/ui/widgets/audio_visualizer_bg.dart';
import 'package:cubix_blast/ui/widgets/hold_piece_preview.dart';

/// Power mode game screen.
class PowerScreen extends StatefulWidget {
  const PowerScreen({super.key});

  @override
  State<PowerScreen> createState() => _PowerScreenState();
}

class _PowerScreenState extends State<PowerScreen> with WidgetsBindingObserver {
  late final PowerEngine _engine;
  final ValueNotifier<int> _frameNotifier = ValueNotifier(0);
  final FocusNode _focusNode = FocusNode();

  double _accumulatedPanX = 0;
  bool _panVerticalTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = PowerEngine();
    _engine.reset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frameNotifier.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden) &&
        _engine.state.status == GameStatus.playing) {
      _engine.togglePause();
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _engine.moveLeft();
      case LogicalKeyboardKey.arrowRight:
        _engine.moveRight();
      case LogicalKeyboardKey.arrowUp:
        _engine.rotateClockwise();
      case LogicalKeyboardKey.arrowDown:
        _engine.softDrop();
      case LogicalKeyboardKey.space:
        _engine.hardDrop();
      case LogicalKeyboardKey.keyP:
      case LogicalKeyboardKey.escape:
        _engine.togglePause();
      case LogicalKeyboardKey.keyR:
        if (_engine.state.status == GameStatus.gameOver) {
          _engine.reset();
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      appBar: AppBar(
        title: const Text('PODERES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GameGestureDetector(
        onMoveLeft: _engine.moveLeft,
        onMoveRight: _engine.moveRight,
        onHardDrop: _engine.hardDrop,
        onHoldPiece: _engine.holdPiece,
        onRotateClockwise: _engine.rotateClockwise,
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: GameLoopWidget(
            engine: _engine,
            frameNotifier: _frameNotifier,
            builder: (context) => Stack(children: [_buildLayout()]),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight - 120;
        final maxW = constraints.maxWidth;
        final maxAllowedW = maxW - 230 > 0 ? maxW - 230 : maxW * 0.3;
        final canvasW = (maxH * 0.5).clamp(0.0, min(maxW * 0.5, maxAllowedW));
        final canvasH = canvasW * 2; // 10:20 ratio

        final theme = GameThemes.getTheme(ScoreManager.currentTheme);
        final currentColor =
            theme.backgroundColors[(_engine.state.level - 1) %
                theme.backgroundColors.length];
        final tempo = 1.0 + (_engine.state.level * 0.15);

        return Stack(
          children: [
            Positioned.fill(
              child: AudioVisualizerBg(
                color: currentColor,
                tempoMultiplier: tempo,
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'HOLD',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 3,
                              color: const Color(
                                0xFF00E5FF,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          HoldPiecePreview(
                            piece: _engine.heldPiece,
                            canHold: _engine.canHold,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 100,
                            child: ScoreBoard(
                              state: _engine.state,
                              highScore: _engine.highScore,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      Transform.translate(
                        offset: Offset(
                          _engine.shakeTimer > 0
                              ? (sin(_engine.state.elapsedSeconds * 50) *
                                    15 *
                                    _engine.shakeTimer)
                              : 0,
                          _engine.shakeTimer > 0
                              ? (cos(_engine.state.elapsedSeconds * 60) *
                                    15 *
                                    _engine.shakeTimer)
                              : 0,
                        ),
                        child: Container(
                          width: canvasW,
                          height: canvasH,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF1A2332),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF00E5FF,
                                ).withValues(alpha: 0.08),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: CustomPaint(
                              painter: PowerPainter(
                                engine: _engine,
                                repaint: _frameNotifier,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'NEXT',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 3,
                              color: const Color(
                                0xFF00E5FF,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          NextPiecePreview(piece: _engine.nextPiece),
                          const SizedBox(height: 32),
                          _buildPowerButton(
                            icon: Icons.hourglass_bottom,
                            cooldown: _engine.slowMoCooldown,
                            maxCooldown: 40.0,
                            color: const Color(0xFF00E5FF),
                            onTap: () => _engine.activateSlowMo(),
                          ),
                          const SizedBox(height: 16),
                          _buildPowerButton(
                            icon: Icons.local_fire_department,
                            cooldown: _engine.bombCooldown,
                            maxCooldown: 30.0,
                            color: const Color(0xFFFF1744),
                            onTap: () => _engine.activateBomb(),
                          ),
                          const SizedBox(height: 16),
                          _buildPowerButton(
                            icon: Icons.vertical_align_center,
                            cooldown: _engine.swapCooldown,
                            maxCooldown: 45.0,
                            color: const Color(0xFF00E676),
                            onTap: () => _engine.swapToI(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
            if (_engine.state.status == GameStatus.gameOver ||
                _engine.state.status == GameStatus.paused)
              OverlayMenu(
                title: _engine.state.status == GameStatus.gameOver
                    ? 'GAME OVER'
                    : 'PAUSED',
                score: _engine.state.score,
                bestScore: _engine.highScore,
                onResume: _engine.state.status == GameStatus.paused
                    ? _engine.togglePause
                    : null,
                onRestart: () {
                  _engine.reset();
                },
                onHome: () {
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildPowerButton({
    required IconData icon,
    required double cooldown,
    required double maxCooldown,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isCoolingDown = cooldown > 0;
    final progress = isCoolingDown ? cooldown / maxCooldown : 0.0;
    final activeColor = isCoolingDown ? Colors.grey : color;

    return GestureDetector(
      onTap: isCoolingDown ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: isCoolingDown
                  ? []
                  : [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: Icon(icon, color: activeColor, size: 28),
          ),
          if (isCoolingDown)
            Positioned.fill(
              child: CircularProgressIndicator(
                value: 1.0 - progress,
                color: color,
                backgroundColor: Colors.transparent,
                strokeWidth: 3,
              ),
            ),
          if (isCoolingDown)
            Text(
              cooldown.ceil().toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }
}
