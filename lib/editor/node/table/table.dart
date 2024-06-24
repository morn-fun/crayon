import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart' hide RichText, TableCell;

import '../../../../editor/extension/collection.dart';
import '../../../../editor/extension/unmodifiable.dart';
import '../../core/context.dart';
import '../../core/copier.dart';
import '../../cursor/basic.dart';
import '../../cursor/table.dart';
import '../../exception/editor_node.dart';
import '../../widget/nodes/table.dart';
import '../basic.dart';
import '../rich_text/rich_text_span.dart';
import 'generator/deletion.dart';
import 'generator/depth.dart';
import 'generator/newline.dart';
import 'generator/paste.dart';
import 'generator/select_all.dart';
import 'generator/styles.dart';
import 'generator/typing.dart';
import 'table_cell.dart';
import 'table_cell_list.dart';

class TableNode extends EditorNode {
  TableNode.from(List<TableCellList> table, List<double> widths,
      {super.id, super.depth, this.initWidth = 200.0})
      : tableAndWidths = _buildInitTableAndWith(table, widths, initWidth);

  TableNode from(List<TableCellList> table, List<double> widths,
          {String? id, int? depth, double? initWidth}) =>
      TableNode.from(
        id == null ? table : table.map((e) => e.newIdCellList()).toList(),
        widths,
        id: id ?? this.id,
        depth: depth ?? this.depth,
        initWidth: initWidth ?? this.initWidth,
      );

  final TableAndWidths tableAndWidths;
  final double initWidth;

  static TableAndWidths _buildInitTableAndWith(
      List<TableCellList> table, List<double> widths, double initWidth) {
    if (table.isEmpty) {
      final table = UnmodifiableListView([TableCellList.empty()]);
      return TableAndWidths(
          table,
          UnmodifiableListView(
              List.generate(table.first.length, (index) => initWidth)));
    }
    assert(table.first.length == widths.length);
    return TableAndWidths(
        UnmodifiableListView(table), UnmodifiableListView(widths));
  }

  UnmodifiableListView<TableCellList> get table => tableAndWidths.table;

  UnmodifiableListView<double> get widths => tableAndWidths.widths;

  int get rowCount => table.length;

  int get columnCount => table.first.length;

  TableCell get lastCell => table.last.last;

  TableCell get firstCell => table.first.first;

  TableCellList row(int row) => table[row];

  TableCellList column(int column) =>
      TableCellList(List.generate(rowCount, (i) => table[i].getCell(column)));

  TableCell getCell(CellPosition p) => table[p.row].getCell(p.column);

  TableNode insertRows(int index, List<TableCellList> rows) {
    for (var r in rows) {
      assert(r.length == columnCount);
    }
    return from(table.insertMore(index, rows), widths);
  }

  TableNode insertColumns(int index, List<ColumnInfo> columns) {
    final rows = List.generate(rowCount, (i) => <TableCell>[]);
    for (var i = 0; i < columns.length; ++i) {
      var column = columns[i].column;
      assert(column.length == rowCount);
      for (var j = 0; j < column.cells.length; ++j) {
        var cell = column.cells[j];
        rows[j].add(cell);
      }
    }
    List<TableCellList> list = [];
    for (var l in table) {
      list.add(l.insert(index, rows[list.length]));
    }
    return from(
        list, widths.insertMore(index, columns.map((e) => e.width).toList()));
  }

  TableNode removeRows(int begin, int end) {
    final newTable = table.replaceMore(begin, end, []);
    if (newTable.isEmpty) throw TableIsEmptyException();
    return from(newTable, widths);
  }

  TableNode removeColumns(int begin, int end) {
    final newWidths = widths.replaceMore(begin, end, []);
    List<TableCellList> newTable = [];
    for (var cellList in table) {
      final list = cellList.replace(begin, end, [], initNum: 0);
      if (list.length == 0) throw TableIsEmptyException();
      newTable.add(list);
    }
    return from(newTable, newWidths);
  }

  TableNode updateCell(int row, int column, ValueCopier<TableCell> copier) {
    final newTable = table.update(row, (t) => t.update(column, copier));
    return from(newTable, widths);
  }

  TableNode updateMore(CellPosition begin, CellPosition end,
      ValueCopier<List<TableCellList>> copier) {
    assert(!begin.sameCell(end));
    final bottomRight = begin.bottomRight(end);
    final topLeft = begin.topLeft(end);
    List<TableCellList> oldCellLists = [];
    for (var i = topLeft.row; i <= bottomRight.row; ++i) {
      var l = table[i];
      oldCellLists.add(TableCellList(
          l.cells.sublist(topLeft.column, bottomRight.column + 1)));
    }
    final newCellLists = copier.call(oldCellLists);
    assert(newCellLists.length == oldCellLists.length);
    final newTable = table.updateMore(topLeft.row, bottomRight.row + 1, (t) {
      List<TableCellList> list = [];
      for (var i = 0; i < t.length; ++i) {
        var cells = t[i].cells;
        var oldCells = oldCellLists[i].cells;
        var newCells = newCellLists[i].cells;
        assert(oldCells.length == newCells.length);
        list.add(TableCellList(cells.replaceMore(
            topLeft.column, bottomRight.column + 1, newCells)));
      }
      return list;
    });
    return from(newTable, widths);
  }

  bool wholeContain(SingleNodeCursor? cursor) {
    if (cursor is! SelectingNodeCursor) return false;
    var left = cursor.left;
    var right = cursor.right;
    return left == beginPosition && right == endPosition;
  }

  Set<int> selectedRows(SingleNodeCursor? cursor) {
    if (cursor is! SelectingNodeCursor) return {};
    try {
      final p = cursor.as<TablePosition>();
      final lp = p.left.cellPosition;
      final rp = p.right.cellPosition;
      final topLeftP = lp.topLeft(rp);
      final bottomRightP = lp.bottomRight(rp);
      if (bottomRightP.column - topLeftP.column < columnCount - 1) return {};
      return List.generate(
          bottomRightP.row - topLeftP.row + 1, (i) => i + topLeftP.row).toSet();
    } on TypeError {
      return {};
    }
  }

  Set<int> selectedColumns(SingleNodeCursor? cursor) {
    if (cursor is! SelectingNodeCursor) return {};
    try {
      final p = cursor.as<TablePosition>();
      final lp = p.left.cellPosition;
      final rp = p.right.cellPosition;
      final topLeftP = lp.topLeft(rp);
      final bottomRightP = lp.bottomRight(rp);
      if (bottomRightP.row - topLeftP.row < rowCount - 1) return {};
      return List.generate(bottomRightP.column - topLeftP.column + 1,
          (i) => i + topLeftP.column).toSet();
    } on TypeError {
      return {};
    }
  }

  BasicCursor? getCursorInCell(
      SingleNodeCursor? cursor, CellPosition cellPosition) {
    final c = cursor;
    try {
      if (c is EditingCursor) {
        final editingCursor = c.as<TablePosition>();
        if (editingCursor.position.cellPosition == cellPosition) {
          return editingCursor.position.cursor;
        }
        return null;
      }
      if (c is SelectingNodeCursor) {
        final selectingCursor = c.as<TablePosition>();
        final begin = selectingCursor.begin;
        final end = selectingCursor.end;
        bool containsSelf =
            cellPosition.containSelf(begin.cellPosition, end.cellPosition);
        if (!containsSelf) return null;
        if (begin.sameCell(end)) {
          final sameIndex = begin.index == end.index;
          if (sameIndex) {
            return SelectingNodeCursor(
                begin.index, begin.position, end.position);
          }
          return SelectingNodesCursor(begin.cursor, end.cursor);
        }
        return getCell(cellPosition).selectAllCursor;
      }
    } on TypeError {
      return null;
    }
    return null;
  }

  @override
  Widget build(NodesOperator operator, NodeBuildParam param, BuildContext c) =>
      RichTable(operator, this, param);

  @override
  TablePosition get beginPosition =>
      TablePosition(CellPosition.zero(), firstCell.beginCursor);

  @override
  TablePosition get endPosition => TablePosition(
      CellPosition(rowCount - 1, columnCount - 1), lastCell.endCursor);

  @override
  EditorNode getFromPosition(
      covariant TablePosition begin, covariant TablePosition end,
      {String? newId}) {
    if (begin == beginPosition && end == endPosition) {
      return from(table, widths, id: newId);
    }
    final left = begin.isLowerThan(end) ? begin : end;
    final right = begin.isLowerThan(end) ? end : begin;
    final leftColumn = min(left.column, right.column);
    final rightColumn = max(left.column, right.column);
    if (left.sameCell(right)) {
      final cell = getCell(left.cellPosition);
      throw GetFromPositionReturnMoreNodesException(
          runtimeType, cell.getNodes(left.cursor, right.cursor));
    } else {
      final newWidths = widths.sublist(leftColumn, rightColumn + 1);
      final List<TableCellList> newTable = [];
      for (int i = left.row; i <= right.row; i++) {
        var cellList = table[i];
        newTable.add(
            TableCellList(cellList.cells.sublist(leftColumn, rightColumn + 1)));
      }
      return from(newTable, newWidths, id: newId);
    }
  }

  @override
  List<EditorNode> getInlineNodesFromPosition(
      covariant TablePosition begin, covariant TablePosition end) {
    try {
      final node = getFromPosition(begin, end);
      if (node is TableNode) {
        List<EditorNode> nodes = [];
        for (var cellList in node.table) {
          for (var cell in cellList.cells) {
            nodes.addAll(cell.nodes);
          }
        }
        return nodes;
      } else {
        return [node];
      }
    } on GetFromPositionReturnMoreNodesException catch (e) {
      return e.nodes;
    }
  }

  @override
  EditorNode merge(EditorNode other, {String? newId}) {
    if (other is TableNode) {
      var oldTable = List.of(table);
      var newTable = List.of(other.table);
      var mergedTable = <TableCellList>[];
      final diffCount = (columnCount - other.columnCount).abs();
      if (columnCount < other.columnCount) {
        final newNode = insertColumns(
            columnCount,
            List.generate(diffCount, (i) {
              return ColumnInfo(
                  TableCellList(
                      List.generate(rowCount, (index) => TableCell.empty())),
                  initWidth);
            }));
        mergedTable.addAll(newNode.table);
        mergedTable.addAll(newTable);
      } else if (columnCount > other.columnCount) {
        final newNode = other.insertColumns(
            other.columnCount,
            List.generate(diffCount, (i) {
              return ColumnInfo(
                  TableCellList(List.generate(
                      other.rowCount, (index) => TableCell.empty())),
                  initWidth);
            }));
        mergedTable.addAll(oldTable);
        mergedTable.addAll(newNode.table);
      } else {
        mergedTable.addAll(oldTable);
        mergedTable.addAll(newTable);
      }
      return from(mergedTable, widths.mergeLists(other.widths), id: newId);
    } else {
      throw UnableToMergeException('$runtimeType', '${other.runtimeType}');
    }
  }

  @override
  EditorNode newNode({String? id, int? depth}) =>
      from(table, widths, id: id, depth: depth);

  @override
  NodeWithCursor onEdit(EditingData data) {
    final type = data.type;
    final generator = _editingGenerator[type.name];
    if (generator == null) {
      throw NodeUnsupportedException(
          runtimeType, 'onEdit without generator', data);
    }
    return generator.call(data.as<TablePosition>(), this);
  }

  @override
  NodeWithCursor onSelect(SelectingData data) {
    final type = data.type;
    final generator = _selectingGenerator[type.name];
    if (generator == null) {
      throw NodeUnsupportedException(
          runtimeType, 'onSelect without generator', data);
    }
    return generator.call(data.as<TablePosition>(), this);
  }

  @override
  String get text => table.map((e) => e.text).join('\n');

  @override
  Map<String, dynamic> toJson() =>
      {'type': '$runtimeType', 'table': table.map((e) => e.toJson()).toList()};
}

final _editingGenerator = <String, _NodeGeneratorWhileEditing>{
  EventType.delete.name: (d, n) => deleteWhileEditing(d, n),
  EventType.newline.name: (d, n) => newlineWhileEditing(d, n),
  EventType.selectAll.name: (d, n) => selectAllWhileEditing(d, n),
  EventType.typing.name: (d, n) => typingWhileEditing(d, n),
  EventType.paste.name: (d, n) => pasteWhileEditing(d, n),
  EventType.increaseDepth.name: (d, n) => increaseDepthWhileEditing(d, n),
  EventType.decreaseDepth.name: (d, n) => decreaseDepthWhileEditing(d, n),
};

final _selectingGenerator = <String, _NodeGeneratorWhileSelecting>{
  EventType.delete.name: (d, n) => deleteWhileSelecting(d, n),
  EventType.newline.name: (d, n) => newlineWhileSelecting(d, n),
  EventType.selectAll.name: (d, n) => selectAllWhileSelecting(d, n),
  EventType.paste.name: (d, n) => pasteWhileSelecting(d, n),
  EventType.increaseDepth.name: (d, n) => increaseDepthWhileSelecting(d, n),
  EventType.decreaseDepth.name: (d, n) => decreaseDepthWhileSelecting(d, n),
  ...Map.fromEntries(RichTextTag.values.map((e) => MapEntry(
      e.name, (d, n) => styleRichTextNodeWhileSelecting(d, n, e.name))))
};

typedef _NodeGeneratorWhileEditing = NodeWithCursor Function(
    EditingData<TablePosition> data, TableNode node);

typedef _NodeGeneratorWhileSelecting = NodeWithCursor Function(
    SelectingData<TablePosition> data, TableNode node);

class TableAndWidths {
  final UnmodifiableListView<TableCellList> table;
  final UnmodifiableListView<double> widths;

  TableAndWidths(this.table, this.widths);
}

class ColumnInfo {
  final TableCellList column;
  final double width;

  ColumnInfo(this.column, this.width);
}
