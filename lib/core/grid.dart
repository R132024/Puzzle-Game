/// Generic 2D grid data structure with collision detection.
///
/// Pure Dart – no Flutter imports.
library;

import 'piece.dart';

/// A mutable 2D grid of nullable integers.
///
/// `null` = empty cell, `int` = color index of the block occupying the cell.
class Grid {
  Grid(this.rows, this.cols) : _cells = List.filled(rows * cols, null);

  Grid.from(Grid other)
      : rows = other.rows,
        cols = other.cols,
        _cells = List<int?>.from(other._cells);

  final int rows;
  final int cols;
  final List<int?> _cells;

  // ─── Cell access ──────────────────────────────────────────────

  int? getCell(int row, int col) {
    if (!inBounds(row, col)) return null;
    return _cells[row * cols + col];
  }

  void setCell(int row, int col, int? value) {
    if (inBounds(row, col)) {
      _cells[row * cols + col] = value;
    }
  }

  /// Whether the coordinate is inside the grid.
  bool inBounds(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  /// Whether the cell is empty (null) **and** in bounds.
  bool isEmpty(int row, int col) => inBounds(row, col) && getCell(row, col) == null;

  // ─── Piece interaction ────────────────────────────────────────

  /// Returns `true` if placing [piece] at its current position would
  /// collide with existing blocks or go out of bounds.
  bool collides(CubixPiece piece) {
    for (final cell in piece.absoluteCells) {
      if (!inBounds(cell.row, cell.col) || getCell(cell.row, cell.col) != null) {
        return true;
      }
    }
    return false;
  }

  /// Stamps the [piece] onto the grid permanently.
  void lockPiece(CubixPiece piece) {
    for (final cell in piece.absoluteCells) {
      setCell(cell.row, cell.col, piece.colorIndex);
    }
  }

  // ─── Row operations ───────────────────────────────────────────

  /// Returns `true` if every cell in [row] is occupied.
  bool isRowFull(int row) {
    for (int c = 0; c < cols; c++) {
      if (getCell(row, c) == null) return false;
    }
    return true;
  }

  /// Clears [row] by setting every cell to `null`.
  void clearRow(int row) {
    for (int c = 0; c < cols; c++) {
      setCell(row, c, null);
    }
  }

  /// Copies contents of [srcRow] into [dstRow].
  void copyRow(int srcRow, int dstRow) {
    for (int c = 0; c < cols; c++) {
      setCell(dstRow, c, getCell(srcRow, c));
    }
  }

  /// Clears the entire grid.
  void clear() => _cells.fillRange(0, _cells.length, null);

  // ─── Debug ────────────────────────────────────────────────────

  @override
  String toString() {
    final buf = StringBuffer();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final v = getCell(r, c);
        buf.write(v == null ? '.' : v.toString());
      }
      buf.writeln();
    }
    return buf.toString();
  }
}
