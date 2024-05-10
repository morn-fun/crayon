
import '../core/copier.dart';
import '../exception/editor_node.dart';
import '../../../editor/cursor/rich_text.dart';
import 'basic.dart';
import 'node_position.dart';

class TablePosition implements NodePosition {
  final EditingCursor cursor;
  final CellIndex cellIndex;

  TablePosition(this.cellIndex, this.cursor);

  TablePosition.zero()
      : cellIndex = CellIndex.zero(),
        cursor = EditingCursor(0, RichTextNodePosition.zero());

  int get row => cellIndex.row;

  int get column => cellIndex.column;

  bool inSameCell(TablePosition other) =>
      row == other.row && column == other.column;

  int get index => cursor.index;

  NodePosition get position => cursor.position;

  TablePosition copy({
    ValueCopier<CellIndex>? cellIndex,
    ValueCopier<EditingCursor>? cursor,
  }) =>
      TablePosition(
          cellIndex?.call(this.cellIndex) ?? this.cellIndex,
          cursor?.call(this.cursor) ?? this.cursor);

  @override
  bool isLowerThan(NodePosition other) {
    if (other is! TablePosition) {
      throw NodePositionDifferentException(runtimeType, other.runtimeType);
    }
    if (row < other.row) return true;
    if (column < other.column) return true;
    return cursor.isLowerThan(other.cursor);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TablePosition &&
          runtimeType == other.runtimeType &&
          cursor == other.cursor &&
          cellIndex == other.cellIndex;

  @override
  int get hashCode => cursor.hashCode ^ cellIndex.hashCode;

  @override
  String toString() {
    return 'TablePosition{cursor: $cursor, cellIndex: $cellIndex}';
  }

  SingleNodePosition cursorToPosition(BasicCursor cursor) {
    if (cursor is EditingCursor) {
      return EditingPosition(copy(cursor: to(cursor)));
    }
    if (cursor is SelectingNodeCursor) {
      final index = cursor.index;
      return SelectingPosition(
        copy(cursor: to(EditingCursor(index, cursor.left))),
        copy(cursor: to(EditingCursor(index, cursor.right))),
      );
    }
    if (cursor is SelectingNodesCursor) {
      return SelectingPosition(
          copy(cursor: to(cursor.left)), copy(cursor: to(cursor.right)));
    }
    return EditingPosition(this);
  }
}

class CellIndex {
  final int row;
  final int column;

  CellIndex(this.row, this.column);

  CellIndex.zero()
      : row = 0,
        column = 0;

  @override
  String toString() {
    return 'CellIndex{row: $row, column: $column}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellIndex &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          column == other.column;

  @override
  int get hashCode => row.hashCode ^ column.hashCode;
}
