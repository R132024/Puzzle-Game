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
import 'package:cubix_blast/core/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:cubix_blast/core/combat_logic.dart';
import 'line_clearer.dart';

class ClassicEngine implements GameEngine {
  ClassicEngine({int? seed})
    : _factory = PieceFactory(seed: seed),
      _grid = Grid(gridRows, gridColumns);

  final PieceFactory _factory;
  final Grid _grid;
  final LineClearer _lineClearer = const LineClearer();

  @override
  void Function(int damage)? onGarbageSent;

  @override
  void receiveGarbage(int lines) {
    pendingGarbage += lines;
  }

  @override
  double reviveCountdown = 0.0;

  // ─── Game state ──────────────────────────────────────────────────

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
  LastMoveType _lastMoveType = LastMoveType.none;
  bool _b2bActive = false;
  @override
  int pendingGarbage = 0;

  /// The grid of locked blocks (exposed for rendering).
  Grid get grid => _grid;

  /// Rows that were just cleared (for animation). Cleared after one frame.
  List<int> lastClearedRows = [];

  /// Timers for cleared rows for animation (row index -> remaining seconds).
  Map<int, double> clearedRowTimers = {};

  int _initialLevel = 1;

  // ─── Internals ──────────────────────────────────────────────

  double _dropTimer = 0;
  double _lockTimer = 0;
  bool _isLocking = false;
  bool _isFastDropping = false;

  double get _dropInterval =>
      max(0.03, baseDropInterval - (state.level - 1) * 0.08);

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
    _b2bActive = false;
    pendingGarbage = 0;
    _lastMoveType = LastMoveType.none;
    _spawnPiece();
  }

  @override
  void forceGameOver() {
    state = state.copyWith(status: GameStatus.gameOver);
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
  void revive() {
    if (state.status != GameStatus.gameOver) return;
    
    // Clear bottom 4 lines
    for (int r = gridRows - 4; r < gridRows; r++) {
      for (int c = 0; c < gridColumns; c++) {
        _grid.setCell(r, c, null);
      }
    }
    
    // Shift everything else down by 4
    for (int r = gridRows - 5; r >= 0; r--) {
      for (int c = 0; c < gridColumns; c++) {
        final cell = _grid.getCell(r, c);
        _grid.setCell(r, c, null);
        _grid.setCell(r + 4, c, cell);
      }
    }

    reviveCountdown = 3.99;
    state = state.copyWith(status: GameStatus.playing);
    _spawnPiece();
  }

  @override
  void update(double dt) {
    if (state.status != GameStatus.playing) return;

    if (reviveCountdown > 0) {
      reviveCountdown -= dt;
      if (reviveCountdown < 0) reviveCountdown = 0;
      return; // Pause the game loop while counting down
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
      _lastMoveType = LastMoveType.move;
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
      _lastMoveType = LastMoveType.move;
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
      _lastMoveType = LastMoveType.rotation;
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
          _lastMoveType = LastMoveType.rotation;
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
      _lastMoveType = LastMoveType.drop;
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
    _lastMoveType = LastMoveType.drop;

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
    if (state.status != GameStatus.playing || activePiece == null || !canHold) {
      return;
    }

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
    
    // Detect T-Spin before locking
    final tSpin = CombatLogic.detectTSpin(activePiece!, _grid, _lastMoveType);
    
    _grid.lockPiece(activePiece!);

    if (_grid.checkTopOut()) {
      AudioService.instance.playPerderGanar();
      state = state.copyWith(status: GameStatus.gameOver);
      return;
    }

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
      
      bool isTetris = result.count == 4;
      bool isB2BEligible = isTetris || tSpin != TSpinType.none;
      bool isB2B = _b2bActive && isB2BEligible;
      
      if (tSpin != TSpinType.none) {
        final spinText = tSpin == TSpinType.mini ? "T-SPIN MINI" : "T-SPIN";
        floatingTexts.add(FloatingText(spinText, 2.0, 0xFFFF0055));
      }
      
      if (isB2B) {
        floatingTexts.add(FloatingText('BACK-TO-BACK!', 1.5, 0xFFFFD600));
      }
      
      // Calculate damage
      int damage = CombatLogic.calculateDamage(
        linesCleared: result.count,
        tSpin: tSpin,
        b2b: isB2B,
        combo: currentCombo,
        perfectClear: _isPerfectClear(),
      );
      
      if (damage > 0) {
        if (pendingGarbage > 0) {
          int offset = min(pendingGarbage, damage);
          pendingGarbage -= offset;
          damage -= offset;
        }
        if (damage > 0 && onGarbageSent != null) {
          onGarbageSent!(damage);
        }
      }

      if (isB2BEligible) {
        _b2bActive = true;
      } else {
        _b2bActive = false;
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
      
      // Si la pieza se fija sin limpiar líneas y hay basura pendiente, insertarla
      if (pendingGarbage > 0) {
        _spawnGarbage();
      }
    }

    activePiece = null;
    _isLocking = false;
    _lockTimer = 0;
    _lastMoveType = LastMoveType.none;

    _spawnPiece();
  }
  
  bool _isPerfectClear() {
    for (int r = 0; r < gridRows; r++) {
      if (!_grid.isEmpty(r, 0)) { // quick check is sufficient?
         for (int c = 0; c < gridColumns; c++) {
           if (!_grid.isEmpty(r, c)) return false;
         }
      }
    }
    return true;
  }
  
  void _spawnGarbage() {
    int holeCol = Random().nextInt(gridColumns);

    if (_grid.checkGarbageGameOver(pendingGarbage)) {
      AudioService.instance.playPerderGanar();
      state = state.copyWith(status: GameStatus.gameOver);
      return;
    }

    _grid.insertGarbageLines(pendingGarbage, holeCol);
    
    if (activePiece != null) {
      activePiece = activePiece!.moved(-pendingGarbage, 0);
    }
    
    pendingGarbage = 0;
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
