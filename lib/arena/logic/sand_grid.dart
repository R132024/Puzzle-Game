/// Fine-grained particle grid for Arena mode.
///
/// Each cell is either empty or contains a sand grain with a color index.
/// Uses double-buffering for consistent cellular automaton updates.
///
/// Pure Dart – no Flutter imports.
library;

import 'package:cubix_blast/core/constants.dart';

/// Represents a single sand grain.
class SandGrain {
  const SandGrain(this.colorIndex);
  final int colorIndex;
}

/// Double-buffered sand particle grid.
class SandGrid {
  SandGrid({int? cols, int? rows})
      : cols = cols ?? sandColumns,
        rows = rows ?? sandRows,
        _current = List<SandGrain?>.filled(
          (cols ?? sandColumns) * (rows ?? sandRows),
          null,
        ),
        _next = List<SandGrain?>.filled(
          (cols ?? sandColumns) * (rows ?? sandRows),
          null,
        );

  final int cols;
  final int rows;
  List<SandGrain?> _current;
  List<SandGrain?> _next;

  /// Whether any grains have moved in the last step.
  bool hasActivity = false;

  // ─── Cell access ──────────────────────────────────────────────

  SandGrain? getCell(int row, int col) {
    if (!inBounds(row, col)) return null;
    return _current[row * cols + col];
  }

  void setCell(int row, int col, SandGrain? grain) {
    if (inBounds(row, col)) {
      _current[row * cols + col] = grain;
    }
  }

  SandGrain? getNext(int row, int col) {
    if (!inBounds(row, col)) return null;
    return _next[row * cols + col];
  }

  void setNext(int row, int col, SandGrain? grain) {
    if (inBounds(row, col)) {
      _next[row * cols + col] = grain;
    }
  }

  bool inBounds(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  bool isEmpty(int row, int col) =>
      inBounds(row, col) && _current[row * cols + col] == null;

  bool isNextEmpty(int row, int col) =>
      inBounds(row, col) && _next[row * cols + col] == null;

  // ─── Buffer management ───────────────────────────────────────

  /// Copy current state into next buffer before simulation step.
  void prepareNextBuffer() {
    for (int i = 0; i < _current.length; i++) {
      _next[i] = _current[i];
    }
  }

  /// Swap current ↔ next after simulation step.
  void swapBuffers() {
    final tmp = _current;
    _current = _next;
    _next = tmp;
  }

  /// Clear both buffers.
  void clear() {
    _current.fillRange(0, _current.length, null);
    _next.fillRange(0, _next.length, null);
  }

  // ─── Bulk operations ─────────────────────────────────────────

  /// Place a block of sand grains (e.g., from a tetromino cell explosion).
  ///
  /// [topRow] and [leftCol] are in sand-grid coordinates.
  /// Fills a [sandScale]×[sandScale] area with grains of [colorIndex].
  void placeBlock(int topRow, int leftCol, int colorIndex) {
    final grain = SandGrain(colorIndex);
    for (int r = 0; r < sandScale; r++) {
      for (int c = 0; c < sandScale; c++) {
        setCell(topRow + r, leftCol + c, grain);
      }
    }
  }

  /// Remove all grains at positions in the set.
  void removeGrains(Set<int> flatIndices) {
    for (final i in flatIndices) {
      if (i >= 0 && i < _current.length) {
        _current[i] = null;
      }
    }
  }

  /// Returns a flat index for (row, col).
  int flatIndex(int row, int col) => row * cols + col;

  /// Access the raw current buffer for rendering.
  List<SandGrain?> get currentBuffer => _current;
}
