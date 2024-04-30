import '../core/copier.dart';
import '../exception/editor_node.dart';
import 'basic.dart';
import 'node_position.dart';
import 'table_cell.dart';

class TablePosition implements NodePosition {
  final int row;
  final int column;
  final TableCellPosition cellPosition;

  TablePosition(this.row, this.column, this.cellPosition);

  TablePosition.empty({bool atEdge = false})
      : row = -1,
        column = -1,
        cellPosition = TableCellPosition.empty(atEdge: atEdge);

  TablePosition.zero({bool atEdge = false})
      : row = 0,
        column = 0,
        cellPosition = TableCellPosition.zero(atEdge: atEdge);

  bool inSameCell(TablePosition other) =>
      row == other.row && column == other.column;

  int get index => cellPosition.index;

  NodePosition get position => cellPosition.position;

  TablePosition copy({
    ValueCopier<int>? row,
    ValueCopier<int>? column,
    ValueCopier<TableCellPosition>? position,
  }) =>
      TablePosition(
          row?.call(this.row) ?? this.row,
          column?.call(this.column) ?? this.column,
          position?.call(cellPosition) ?? cellPosition);

  @override
  bool isLowerThan(NodePosition other) {
    if (other is! TablePosition) {
      throw NodePositionDifferentException(runtimeType, other.runtimeType);
    }
    if (row < other.row) return true;
    if (column < other.column) return true;
    return cellPosition.isLowerThan(other.cellPosition);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TablePosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          column == other.column &&
          cellPosition == other.cellPosition;

  @override
  int get hashCode => row.hashCode ^ column.hashCode ^ cellPosition.hashCode;

  @override
  String toString() {
    return 'TablePosition{row: $row, column: $column, cellPosition: $cellPosition}';
  }

  SingleNodePosition fromCursor(BasicCursor cursor) {
    if (cursor is EditingCursor) {
      return EditingPosition(
        copy(
          position: (p) => p.copy(
            index: to(cursor.index),
            position: to(cursor.position),
          ),
        ),
      );
    }
    if (cursor is SelectingNodeCursor) {
      final index = cursor.index;
      return SelectingPosition(
        copy(
            position: (p) =>
                p.copy(index: to(index), position: to(cursor.begin))),
        copy(
            position: (p) =>
                p.copy(index: to(index), position: to(cursor.end))),
      );
    }
    if (cursor is SelectingNodesCursor) {
      final begin = cursor.begin;
      final end = cursor.end;
      return SelectingPosition(
          copy(
              position: (p) =>
                  p.copy(index: to(begin.index), position: to(begin.position))),
          copy(
              position: (p) =>
                  p.copy(index: to(end.index), position: to(end.position))));
    }
    return EditingPosition(this);
  }
}
