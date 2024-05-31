import 'dart:math';
import 'dart:ui';
import '../core/copier.dart';
import '../exception/editor_node.dart';
import '../../../editor/cursor/rich_text.dart';
import '../node/table/table.dart';
import 'basic.dart';

class TablePosition extends NodePosition {
  final EditingCursor cursor;
  final CellPosition cellPosition;

  TablePosition(this.cellPosition, this.cursor);

  TablePosition.zero()
      : cellPosition = CellPosition.zero(),
        cursor = EditingCursor(0, RichTextNodePosition.zero());

  int get row => cellPosition.row;

  int get column => cellPosition.column;

  bool sameCell(TablePosition other) =>
      cellPosition.sameCell(other.cellPosition);

  int get index => cursor.index;

  NodePosition get position => cursor.position;

  TablePosition copy({
    ValueCopier<CellPosition>? cellPosition,
    ValueCopier<EditingCursor>? cursor,
  }) =>
      TablePosition(cellPosition?.call(this.cellPosition) ?? this.cellPosition,
          cursor?.call(this.cursor) ?? this.cursor);

  @override
  bool isLowerThan(NodePosition other) {
    if (other is! TablePosition) {
      throw NodePositionDifferentException(runtimeType, other.runtimeType);
    }
    if (row < other.row) return true;
    if (row > other.row) return false;
    if (column < other.column) return true;
    if (column > other.column) return false;
    return cursor.isLowerThan(other.cursor);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TablePosition &&
          runtimeType == other.runtimeType &&
          cursor == other.cursor &&
          cellPosition == other.cellPosition;

  @override
  int get hashCode => cursor.hashCode ^ cellPosition.hashCode;

  @override
  String toString() {
    return 'TablePosition{cellPosition: $cellPosition, cursor: $cursor}';
  }
}

class CellPosition {
  final int row;
  final int column;

  CellPosition(this.row, this.column);

  CellPosition.zero()
      : row = 0,
        column = 0;

  @override
  String toString() {
    return 'CellPosition{row: $row, column: $column}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          column == other.column;

  @override
  int get hashCode => row.hashCode ^ column.hashCode;

  CellPosition topLeft(CellPosition end) {
    int c = min(column, end.column);
    int r = min(row, end.row);
    return CellPosition(r, c);
  }

  CellPosition bottomRight(CellPosition end) {
    int c = max(column, end.column);
    int r = max(row, end.row);
    return CellPosition(r, c);
  }

  CellPosition lastInHorizontal(TableNode node) {
    if (column == 0 && row == 0) throw ArrowLeftBeginException(this);
    if (column == 0) return CellPosition(row - 1, node.columnCount - 1);
    return CellPosition(row, column - 1);
  }

  CellPosition nextInHorizontal(TableNode node) {
    final maxColumn = node.columnCount - 1, maxRow = node.rowCount - 1;
    if (column == maxColumn && row == maxRow) {
      throw ArrowRightEndException(this);
    }
    if (column == maxColumn) return CellPosition(row + 1, 0);
    return CellPosition(row, column + 1);
  }

  CellPosition lastInVertical(TableNode node, Offset offset) {
    if (row == 0) throw ArrowUpTopException(this, offset);
    return CellPosition(row - 1, column);
  }

  CellPosition nextInVertical(TableNode node, Offset offset) {
    if (row == node.rowCount - 1) throw ArrowDownBottomException(this, offset);
    return CellPosition(row + 1, column);
  }

  bool containSelf(CellPosition begin, CellPosition end) {
    final minRow = min(begin.row, end.row);
    final maxRow = max(begin.row, end.row);
    final minColumn = min(begin.column, end.column);
    final maxColumn = max(begin.column, end.column);
    return (minRow <= row && maxRow >= row) &&
        (minColumn <= column && maxColumn >= column);
  }

  bool sameCell(CellPosition other) =>
      row == other.row && column == other.column;
}
