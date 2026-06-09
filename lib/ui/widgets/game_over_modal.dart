import 'package:flutter/material.dart';
import 'package:cubix_blast/core/game_engine.dart';
import 'package:cubix_blast/core/high_score_store.dart';

class GameOverModal extends StatefulWidget {
  const GameOverModal({
    super.key,
    required this.state,
    required this.mode,
    required this.onRetry,
    required this.onMenu,
    required this.onResume,
  });

  final GameState state;
  final String mode;
  final VoidCallback onRetry;
  final VoidCallback onMenu;
  final VoidCallback onResume;

  @override
  State<GameOverModal> createState() => _GameOverModalState();
}

class _GameOverModalState extends State<GameOverModal> {
  late final TextEditingController _nameController;
  bool _saved = false;
  HighScore? _previousRecord;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    if (widget.state.status == GameStatus.gameOver) {
      _loadRecord();
    }
  }

  Future<void> _loadRecord() async {
    final record = await HighScoreStore.getHighScore(widget.mode);
    if (mounted) {
      setState(() {
        _previousRecord = record;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTime(double elapsedSeconds) {
    final int total = elapsedSeconds.floor();
    final int minutes = total ~/ 60;
    final int seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveScore() async {
    final name = _nameController.text.trim().toUpperCase();
    if (name.length == 4) {
      await HighScoreStore.saveHighScore(
        widget.mode,
        widget.state.score,
        widget.state.level,
        name,
      );
      if (mounted) {
        setState(() {
          _saved = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGameOver = widget.state.status == GameStatus.gameOver;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.8 * value.clamp(0.0, 1.0)),
            alignment: Alignment.center,
            child: Transform.scale(
              scale: value,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isGameOver ? 'GAME OVER' : 'PAUSED',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isGameOver) ...[
                        Text(
                          'SCORE: ${widget.state.score}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E676),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TIME: ${_formatTime(widget.state.elapsedSeconds)}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_previousRecord != null &&
                            widget.state.score > _previousRecord!.score)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              '¡NUEVO RÉCORD!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD600),
                              ),
                            ),
                          ),
                        if (!_saved &&
                            (_previousRecord == null ||
                                widget.state.score >
                                    _previousRecord!.score)) ...[
                          TextField(
                            controller: _nameController,
                            maxLength: 4,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: Colors.white,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'ABCD',
                              counterText: '',
                              filled: true,
                              fillColor: Color(0xFF1E293B),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              // Force uppercase and A-Z only
                              final filtered = val.toUpperCase().replaceAll(
                                RegExp(r'[^A-Z]'),
                                '',
                              );
                              if (filtered != val) {
                                _nameController.text = filtered;
                                _nameController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(offset: filtered.length),
                                    );
                              }
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _nameController.text.length == 4
                                ? _saveScore
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text(
                              'Guardar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ] else if (_saved) ...[
                          const Text(
                            '¡Guardado!',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 18,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (isGameOver)
                            ElevatedButton(
                              onPressed: widget.onRetry,
                              child: const Text('REINTENTAR'),
                            )
                          else
                            ElevatedButton(
                              onPressed: widget.onResume,
                              child: const Text('REANUDAR'),
                            ),
                          OutlinedButton(
                            onPressed: widget.onMenu,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white30),
                            ),
                            child: const Text('MENÚ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
