import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cubix_blast/classic/logic/classic_engine.dart';
import 'package:cubix_blast/core/high_score_store.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:cubix_blast/core/audio_service.dart';
import 'package:cubix_blast/core/music_service.dart';
import 'dart:ui';
import 'package:cubix_blast/theme/game_themes.dart';
import 'package:cubix_blast/classic/ui/classic_painter.dart';
import 'package:cubix_blast/core/game_engine.dart';
import 'package:cubix_blast/ui/widgets/game_loop_widget.dart';
import 'package:cubix_blast/ui/widgets/score_board.dart';
import 'package:cubix_blast/ui/widgets/overlay_menu.dart';
import 'package:cubix_blast/ui/widgets/game_over_modal.dart';
import 'package:cubix_blast/ui/widgets/next_piece_preview.dart';

import 'package:cubix_blast/ui/widgets/game_gesture_detector.dart';
import 'package:cubix_blast/ui/widgets/audio_visualizer_bg.dart';
import 'package:cubix_blast/ui/widgets/hold_piece_preview.dart';

/// Classic mode game screen.
class ClassicScreen extends StatefulWidget {
  const ClassicScreen({super.key});

  @override
  State<ClassicScreen> createState() => _ClassicScreenState();
}

class _ClassicScreenState extends State<ClassicScreen>
    with WidgetsBindingObserver {
  late final ClassicEngine _engine;
  final ValueNotifier<int> _frameNotifier = ValueNotifier(0);
  final FocusNode _focusNode = FocusNode();

  double _accumulatedPanX = 0;
  bool _panVerticalTriggered = false;

  bool _initializedLevel = false;
  int _startingLevel = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = ClassicEngine();
    _engine.reset();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedLevel) {
      _initializedLevel = true;
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      _startingLevel = args?['initialLevel'] as int? ?? 1;
      _engine.reset(initialLevel: _startingLevel);
    }
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
          _engine.reset(initialLevel: _startingLevel);
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('CLÁSICO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AudioService.instance.playBoton();
            Navigator.of(context).pop();
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
        ],
      ),
      body: GameGestureDetector(
        onMoveLeft: _engine.moveLeft,
        onMoveRight: _engine.moveRight,
        onHardDrop: _engine.hardDrop,
        onHoldPiece: _engine.holdPiece,
        onRotateClockwise: _engine.rotateClockwise,
        onFastDrop: _engine.setFastDrop,
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
        final maxH = constraints.maxHeight - 140;
        final maxW = constraints.maxWidth;
        final double canvasW = (maxH * 0.5).clamp(0.0, maxW * 0.95).toDouble();
        final canvasH = canvasW * 2; // 10:20 ratio

        final theme = GameThemes.getTheme(ScoreManager.currentTheme);
        final currentColor = Theme.of(context).colorScheme.primary;
        final tempo = 1.0 + (_engine.state.level * 0.15);

        return Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<Color>(
                valueListenable: MusicService.instance.dominantColor,
                builder: (context, dominantColor, child) {
                  return AudioVisualizerBg(
                    color: dominantColor,
                    tempoMultiplier: tempo,
                  );
                },
              ),
            ),
            Column(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _frameNotifier,
                  builder: (context, frame, _) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HoldPiecePreview(
                            piece: _engine.heldPiece,
                            canHold: _engine.canHold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ScoreBoard(
                              state: _engine.state,
                              highScore: _engine.highScore,
                            ),
                          ),
                          const SizedBox(width: 8),
                          NextPiecePreview(piece: _engine.nextPiece),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _frameNotifier,
                      builder: (context, frame, child) {
                        return Transform.translate(
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
                          child: child,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: canvasW,
                          height: canvasH,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: ClassicPainter(
                                  engine: _engine,
                                  repaint: _frameNotifier,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (context, frame, child) {
                if (_engine.state.status == GameStatus.gameOver) {
                  return GameOverModal(
                    state: _engine.state,
                    mode: 'classic',
                    onRetry: () => _engine.reset(initialLevel: _startingLevel),
                    onMenu: () => Navigator.of(context).pop(),
                    onResume: () {},
                  );
                } else if (_engine.state.status == GameStatus.paused) {
                  return OverlayMenu(
                    title: 'PAUSED',
                    score: _engine.state.score,
                    bestScore: _engine.highScore,
                    onResume: _engine.togglePause,
                    onRestart: () => _engine.reset(initialLevel: _startingLevel),
                    onHome: () => Navigator.of(context).pop(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }
}
