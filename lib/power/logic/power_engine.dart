/// Classic mode game engine.
///
/// Implements the [GameEngine] contract with standard block-drop mechanics:
/// gravity, movement, rotation (SRS wall kicks), lock delay, and line clearing.
///
/// Pure Dart – no Flutter imports.
library;

import 'dart:math';
import 'package:cubix_blast/core/constants.dart';
import 'package:cubix_blast/core/game_engine.dart';
import 'package:cubix_blast/core/grid.dart';
import 'package:cubix_blast/core/piece.dart';
import 'package:cubix_blast/core/piece_factory.dart';
import 'package:cubix_blast/core/score_manager.dart';
import 'package:flutter/services.dart';
import 'package:cubix_blast/classic/logic/line_clearer.dart';
import 'package:cubix_blast/core/audio_service.dart';

class PowerEngine implements GameEngine {
  PowerEngine({int? seed})
    : _factory = PieceFactory(seed: seed),
      _grid = Grid(gridRows, gridColumns);

  final PieceFactory _factory;
  final Grid _grid;
  final LineClearer _lineClearer = const LineClearer();

  // ─── State ──────────────────────────────────────────────────

  @override
  GameState state = const GameState();

  @override
  CubixPiece? activePiece;

  @override
  CubixPiece? nextPiece;

  @override
  CubixPiece? heldPiece;

  @override
  bool canHold = true;

  @override
  double shakeTimer = 0.0;

  @override
  List<FloatingText> floatingTexts = [];

  @override
  List<HardDropTrail> hardDropTrails = [];

  @override
  int get highScore => ScoreManager.classicHighScore;

  int currentCombo = 0;

  /// The grid of locked blocks (exposed for rendering).
  Grid get grid => _grid;

  /// Rows that were just cleared (for animation). Cleared after one frame.
  List<int> lastClearedRows = [];

  /// Timers for cleared rows for animation (row index -> remaining seconds).
  Map<int, double> clearedRowTimers = {};

  int _initialLevel = 1;

  // ─── Powers ─────────────────────────────────────────────────

  double slowMoTimer = 0;

  // Cooldowns (in seconds)
  double slowMoCooldown = 0;   // Slow Mo: 20s
  double laserCooldown = 0;    // Láser: 30s
  double meteoriteCooldown = 0; // Meteorito: 40s

  // Animation timers (for visual effects rendered in painter)
  double laserFlashTimer = 0;  // >0 while laser flash visible
  double meteoriteFlashTimer = 0; // >0 while meteorite impact visible

  void activateSlowMo() {
    if (state.status != GameStatus.playing) return;
    if (slowMoCooldown > 0) return;
    slowMoTimer = 10.0; // 10 seconds of slow mo
    slowMoCooldown = 20.0; // 20s cooldown
    AudioService.instance.playPoderLento();
    floatingTexts.add(FloatingText('¡CÁMARA LENTA!', 2.0, 0xFF00E5FF));
    HapticFeedback.mediumImpact();
  }

  /// Láser: clears the bottom 2 rows and drops everything above.
  void activateLaser() {
    if (state.status != GameStatus.playing) return;
    if (laserCooldown > 0) return;

    // Clear the 2 bottom rows
    final bottomRow1 = gridRows - 1;
    final bottomRow2 = gridRows - 2;

    // Clear both rows
    _grid.clearRow(bottomRow1);
    _grid.clearRow(bottomRow2);

    // Drop rows above: shift everything down by 2
    for (int r = gridRows - 3; r >= 0; r--) {
      _grid.copyRow(r, r + 2);
    }
    // Clear the top 2 rows that were copied from
    _grid.clearRow(0);
    _grid.clearRow(1);

    // Animation & feedback
    laserFlashTimer = 0.5;
    laserCooldown = 30.0;
    shakeTimer = 0.25;
    clearedRowTimers[bottomRow1] = 0.4;
    clearedRowTimers[bottomRow2] = 0.4;
    lastClearedRows = [bottomRow1, bottomRow2];
    AudioService.instance.playLaser();
    floatingTexts.add(FloatingText('¡LÁSER!', 2.0, 0xFFFF1744));

    // Award score for the cleared rows
    final scoreAdd = lineScoreTable[min(2, 4)] * state.level;
    final newLines = state.linesCleared + 2;
    final newLevel = _initialLevel + (newLines ~/ linesPerLevel);
    state = state.copyWith(
      score: state.score + scoreAdd,
      linesCleared: newLines,
      level: newLevel,
    );
    ScoreManager.addCoins(20);

    HapticFeedback.heavyImpact();
  }

  /// Meteorito: clears the bottom 6 rows with massive impact.
  void activateMeteorite() {
    if (state.status != GameStatus.playing) return;
    if (meteoriteCooldown > 0) return;

    // Clear bottom 6 rows
    const rowsToClear = 6;
    final clearedRows = <int>[];
    for (int r = gridRows - 1; r >= gridRows - rowsToClear && r >= 0; r--) {
      _grid.clearRow(r);
      clearedRows.add(r);
      clearedRowTimers[r] = 0.6; // longer animation for impact
    }

    // Drop everything above down by 6
    for (int r = gridRows - rowsToClear - 1; r >= 0; r--) {
      _grid.copyRow(r, r + rowsToClear);
    }
    // Clear the top rows
    for (int r = 0; r < rowsToClear && r < gridRows; r++) {
      _grid.clearRow(r);
    }

    // Massive feedback
    meteoriteFlashTimer = 0.7;
    meteoriteCooldown = 40.0;
    shakeTimer = 0.5;
    lastClearedRows = clearedRows;
    AudioService.instance.playMeteorito();
    floatingTexts.add(FloatingText('¡¡METEORITO!!', 2.5, 0xFFFF6D00));

    // Award score
    final scoreAdd = lineScoreTable[4] * state.level; // Treat as tetris-level clear
    final newLines = state.linesCleared + rowsToClear;
    final newLevel = _initialLevel + (newLines ~/ linesPerLevel);
    state = state.copyWith(
      score: state.score + scoreAdd,
      linesCleared: newLines,
      level: newLevel,
    );
    ScoreManager.addCoins(60);

    HapticFeedback.heavyImpact();
  }

  // ─── Internals ──────────────────────────────────────────────

  double _dropTimer = 0;
  double _lockTimer = 0;
  bool _isLocking = false;
  bool _isFastDropping = false;

  double get _dropInterval {
    final base = max(
      0.03,
      baseDropInterval - (state.level - 1) * 0.08,
    );
    return slowMoTimer > 0 ? base * 4.0 : base;
  }

  // ─── Lifecycle ──────────────────────────────────────────────

  @override
  void reset({int initialLevel = 1}) {
    _initialLevel = initialLevel;
    _grid.clear();
    _factory.reset();
    state = GameState(status: GameStatus.playing, level: initialLevel);
    _dropTimer = 0;
    _lockTimer = 0;
    _isLocking = false;
    lastClearedRows = [];
    clearedRowTimers.clear();
    heldPiece = null;
    canHold = true;
    shakeTimer = 0.0;
    floatingTexts.clear();
    hardDropTrails.clear();
    currentCombo = 0;
    // Reset ALL power-up state
    slowMoTimer = 0;
    slowMoCooldown = 0;
    laserCooldown = 0;
    laserFlashTimer = 0;
    meteoriteCooldown = 0;
    meteoriteFlashTimer = 0;
    _spawnPiece();
  }

  @override
  void togglePause() {
    if (state.status == GameStatus.playing) {
      AudioService.instance.playPausa();
      state = state.copyWith(status: GameStatus.paused);
    } else if (state.status == GameStatus.paused) {
      AudioService.instance.playPausa();
      state = state.copyWith(status: GameStatus.playing);
    }
  }

  @override
  void update(double dt) {
    if (state.status != GameStatus.playing) return;

    if (slowMoTimer > 0) {
      slowMoTimer -= dt;
      if (slowMoTimer < 0) slowMoTimer = 0;
    }

    // Decrease cooldowns
    if (slowMoCooldown > 0) {
      slowMoCooldown -= dt;
      if (slowMoCooldown < 0) slowMoCooldown = 0;
    }
    if (laserCooldown > 0) {
      laserCooldown -= dt;
      if (laserCooldown < 0) laserCooldown = 0;
    }
    if (meteoriteCooldown > 0) {
      meteoriteCooldown -= dt;
      if (meteoriteCooldown < 0) meteoriteCooldown = 0;
    }
    // Decrease visual flash timers
    if (laserFlashTimer > 0) {
      laserFlashTimer -= dt;
      if (laserFlashTimer < 0) laserFlashTimer = 0;
    }
    if (meteoriteFlashTimer > 0) {
      meteoriteFlashTimer -= dt;
      if (meteoriteFlashTimer < 0) meteoriteFlashTimer = 0;
    }

    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + dt);
    lastClearedRows = [];

    final rowsToRemove = <int>[];
    for (final entry in clearedRowTimers.entries) {
      final newTime = entry.value - dt;
      if (newTime <= 0) {
        rowsToRemove.add(entry.key);
      } else {
        clearedRowTimers[entry.key] = newTime;
      }
    }
    for (final r in rowsToRemove) {
      clearedRowTimers.remove(r);
    }

    if (shakeTimer > 0) {
      shakeTimer -= dt;
      if (shakeTimer < 0) shakeTimer = 0;
    }

    final textsToRemove = <FloatingText>[];
    for (final t in floatingTexts) {
      t.timer -= dt;
      if (t.timer <= 0) textsToRemove.add(t);
    }
    for (final t in textsToRemove) {
      floatingTexts.remove(t);
    }

    final trailsToRemove = <HardDropTrail>[];
    for (final t in hardDropTrails) {
      t.timer -= dt;
      if (t.timer <= 0) trailsToRemove.add(t);
    }
    for (final t in trailsToRemove) {
      hardDropTrails.remove(t);
    }

    if (activePiece == null) return;

    if (_isLocking) {
      _lockTimer += dt;
      // Check if piece can still fall (player moved it off ledge)
      final below = activePiece!.moved(1, 0);
      if (!_grid.collides(below)) {
        _isLocking = false;
        _lockTimer = 0;
      } else if (_wouldClearLines(activePiece!) || _lockTimer >= lockDelay) {
        _lockPiece();
        return;
      }
    }

    _dropTimer += dt * (_isFastDropping ? 10.0 : 1.0);
    if (_dropTimer >= _dropInterval) {
      _dropTimer = 0;
      _tryMoveDown();
    }
  }

  @override
  void setFastDrop(bool enabled) {
    _isFastDropping = enabled;
  }

  // ─── Player Input ───────────────────────────────────────────

  @override
  void moveLeft() {
    if (state.status != GameStatus.playing || activePiece == null) return;
    final moved = activePiece!.moved(0, -1);
    if (!_grid.collides(moved)) {
      activePiece = moved;
      _resetLockIfMoved();
      HapticFeedback.lightImpact();
    }
  }

  @override
  void moveRight() {
    if (state.status != GameStatus.playing || activePiece == null) return;
    final moved = activePiece!.moved(0, 1);
    if (!_grid.collides(moved)) {
      activePiece = moved;
      _resetLockIfMoved();
      HapticFeedback.lightImpact();
    }
  }

  @override
  void rotateClockwise() {
    if (state.status != GameStatus.playing || activePiece == null) return;
    final piece = activePiece!;
    final newRotation = piece.nextRotation;
    final rotated = piece.rotated(newRotation);

    // Try basic rotation
    if (!_grid.collides(rotated)) {
      activePiece = rotated;
      _resetLockIfMoved();
      HapticFeedback.lightImpact();
      return;
    }

    // Try wall kicks
    final kickKey = '${piece.rotation.index}>${newRotation.index}';
    final kicks = wallKickData[piece.shape]?[kickKey];
    if (kicks != null) {
      for (final kick in kicks) {
        final kicked = rotated.moved(kick.row, kick.col);
        if (!_grid.collides(kicked)) {
          activePiece = kicked;
          _resetLockIfMoved();
          HapticFeedback.lightImpact();
          return;
        }
      }
    }
  }

  @override
  void softDrop() {
    if (state.status != GameStatus.playing || activePiece == null) return;
    final moved = activePiece!.moved(1, 0);
    if (!_grid.collides(moved)) {
      activePiece = moved;
      state = state.copyWith(score: state.score + softDropScore);
      _dropTimer = 0;
    }
  }

  @override
  void hardDrop() {
    if (state.status != GameStatus.playing || activePiece == null) return;
    var piece = activePiece!;
    final startRow = piece.row;
    while (!_grid.collides(piece.moved(1, 0))) {
      piece = piece.moved(1, 0);
    }
    activePiece = piece;

    // Add trail
    for (final cell in piece.absoluteCells) {
      hardDropTrails.add(
        HardDropTrail(
          cell.col,
          startRow + (cell.row - piece.row),
          cell.row,
          piece.colorIndex,
          0.3,
        ),
      );
    }

    final newScore = state.score + 2; // soft drop score
    state = state.copyWith(score: newScore);
    if (newScore > ScoreManager.classicHighScore) {
      ScoreManager.saveClassicScore(newScore);
    }

    shakeTimer = 0.2;
    HapticFeedback.heavyImpact();
    _lockPiece();
  }

  @override
  void holdPiece() {
    if (state.status != GameStatus.playing || activePiece == null || !canHold)
      return;

    final currentShape = activePiece!.shape;
    final currentColor = activePiece!.colorIndex;

    if (heldPiece == null) {
      heldPiece = CubixPiece(
        shape: currentShape,
        colorIndex: currentColor,
        row: 0,
        col: 3,
      );
      _spawnPiece();
    } else {
      final tempShape = heldPiece!.shape;
      final tempColor = heldPiece!.colorIndex;
      heldPiece = CubixPiece(
        shape: currentShape,
        colorIndex: currentColor,
        row: 0,
        col: 3,
      );
      activePiece = CubixPiece(
        shape: tempShape,
        colorIndex: tempColor,
        row: 0,
        col: 3,
      );
      _dropTimer = 0;
    }

    canHold = false;
  }

  // ─── Ghost piece (for preview) ──────────────────────────────

  /// Returns the position where the active piece would land.
  CubixPiece? get ghostPiece {
    if (activePiece == null) return null;
    var ghost = activePiece!;
    while (!_grid.collides(ghost.moved(1, 0))) {
      ghost = ghost.moved(1, 0);
    }
    return ghost;
  }

  // ─── Private helpers ────────────────────────────────────────

  void _tryMoveDown() {
    if (activePiece == null) return;
    final below = activePiece!.moved(1, 0);
    if (!_grid.collides(below)) {
      activePiece = below;
    } else {
      // Lock immediately if lines are cleared
      if (_wouldClearLines(activePiece!)) {
        _lockPiece();
      } else if (!_isLocking) {
        // Start lock delay
        _isLocking = true;
        _lockTimer = 0;
      }
    }
  }

  bool _wouldClearLines(CubixPiece piece) {
    final rows = <int, int>{};
    for (final cell in piece.absoluteCells) {
      if (cell.row >= 0 && cell.row < gridRows) {
        rows[cell.row] = (rows[cell.row] ?? 0) + 1;
      }
    }
    for (final entry in rows.entries) {
      final r = entry.key;
      int existingCells = 0;
      for (int c = 0; c < gridColumns; c++) {
        if (!_grid.isEmpty(r, c)) {
          existingCells++;
        }
      }
      if (existingCells + entry.value >= gridColumns) {
        return true;
      }
    }
    return false;
  }

  void _lockPiece() {
    if (activePiece == null) return;



    _grid.lockPiece(activePiece!);

    // Clear lines
    final result = _lineClearer.clearFullRows(_grid);
    if (result.any) {
      AudioService.instance.playRomperFila();
      lastClearedRows = result.rowsCleared;
      for (final r in result.rowsCleared) {
        clearedRowTimers[r] = 0.4; // 400ms animation
      }
      final newLines = state.linesCleared + result.count;
      final newLevel = _initialLevel + (newLines ~/ linesPerLevel);
      final scoreAdd = lineScoreTable[min(result.count, 4)] * state.level;

      final newScore = state.score + scoreAdd;
      if (newScore > ScoreManager.classicHighScore) {
        ScoreManager.saveClassicScore(newScore);
      }

      ScoreManager.addCoins(result.count * 10);

      if (newLevel > state.level) {
        floatingTexts.add(FloatingText('LEVEL UP!', 3.0, 0xFFFF1744));
      }

      currentCombo++;
      if (currentCombo > 1) {
        floatingTexts.add(
          FloatingText('COMBO x$currentCombo', 1.5, 0xFFFFD600),
        );
      }

      if (result.count >= 4) {
        shakeTimer = 0.3;
        floatingTexts.add(FloatingText('CUBIX BLAST!', 2.0, 0xFF00E5FF));
        HapticFeedback.heavyImpact();
      } else if (result.count > 1) {
        floatingTexts.add(
          FloatingText(
            '${['DOUBLE', 'TRIPLE'][result.count - 2]}!',
            1.0,
            0xFF00E676,
          ),
        );
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }

      state = state.copyWith(
        score: state.score + scoreAdd,
        linesCleared: newLines,
        level: newLevel,
      );
    } else {
      currentCombo = 0;
    }

    activePiece = null;
    _isLocking = false;
    _lockTimer = 0;

    _spawnPiece();
  }

  void _spawnPiece() {
    // Use previewed next piece or generate
    if (nextPiece != null) {
      activePiece = nextPiece!.withPosition(0, 3);
    } else {
      activePiece = _factory.next();
    }
    nextPiece = _factory.next(spawnRow: 0, spawnCol: 3);
    canHold = true;

    // Game over check
    if (_grid.collides(activePiece!)) {
      activePiece = null;
      AudioService.instance.playPerderGanar();
      state = state.copyWith(status: GameStatus.gameOver);
    }

    _dropTimer = 0;
  }

  void _resetLockIfMoved() {
    if (_isLocking) {
      _lockTimer = 0;
    }
  }
}
