import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart' hide RichText, TableCell;

import '../../../../editor/extension/unmodifiable.dart';
import '../../../../editor/node/rich_text/rich_text.dart';
import '../../core/context.dart';
import '../../core/copier.dart';
import '../../cursor/node_position.dart';
import '../../cursor/table.dart';
import '../../exception/editor_node.dart';
import '../../widget/nodes/table.dart';
import '../basic.dart';
import 'generator/deletion.dart';
import 'generator/depth.dart';
import 'generator/newline.dart';
import 'generator/select_all.dart';
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
        table,
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

  List<TableCell> column(int column) =>
      List.generate(columnCount, (i) => table[i].getCell(column));

  TableCell getCell(int row, int column) => table[row].getCell(column);

  TableCell getCellByPosition(TablePosition p) => getCell(p.row, p.column);

  TableNode insertRows(int index, List<TableCellList> rows) {
    for (var r in rows) {
      assert(r.length == columnCount);
    }
    return from(table.insertMore(index, rows), widths);
  }

  TableNode insertColumns(
      int index, List<TableCellList> columns, List<double> widths) {
    final rows = List.generate(rowCount, (index) => <TableCell>[]);
    assert(columns.length == widths.length);
    for (var i = 0; i < columns.length; ++i) {
      var column = columns[i];
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
    return from(list, this.widths.insertMore(index, widths));
  }

  TableNode removeRows(int begin, int end) =>
      from(table.replaceMore(begin, end, []), widths);

  TableNode removeColumns(int begin, int end) {
    final newWidths = widths.replaceMore(begin, end, []);
    List<TableCellList> newTable = [];
    for (var cellList in table) {
      newTable.add(cellList.replace(begin, end, []));
    }
    return from(table, newWidths);
  }

  TableNode updateCell(int row, int column, ValueCopier<TableCell> copier) {
    final newTable = table.update(row, (t) => t.update(column, copier));
    return from(newTable, widths);
  }

  TableNode updateRow(int row, ValueCopier<TableCellList> copier) =>
      from(table.update(row, copier), widths);

  TableNode updateColumn(int column, ValueCopier<TableCellList> copier) {
    List<TableCell> oldColumnCells = [];
    for (var cellList in table) {
      oldColumnCells.add(cellList.getCell(column));
    }
    final newColumnCells = copier.call(TableCellList(oldColumnCells));
    List<TableCellList> newTable = [];
    for (var cellList in table) {
      newTable.add(cellList.update(
          column, (n) => newColumnCells.getCell(newTable.length)));
    }
    return from(table, widths);
  }

  TableNode updateMore(TablePosition begin, TablePosition end,
      ValueCopier<List<TableCellList>> copier) {
    assert(!begin.inSameCell(end));
    final left = begin.isLowerThan(end) ? begin : end;
    final right = begin.isLowerThan(end) ? end : begin;
    final leftColumn = min(left.column, right.column);
    final rightColumn = max(left.column, right.column);
    List<TableCellList> oldCellLists = [];
    for (var i = left.row; i <= right.row; ++i) {
      var cellList = table[i];
      oldCellLists.add(
          TableCellList(cellList.cells.sublist(leftColumn, rightColumn + 1)));
    }
    final newCellLists = copier.call(oldCellLists);
    final newTable = table.updateMore(left.row, right.row + 1, (t) {
      List<TableCellList> list = [];
      for (var i = 0; i < t.length; ++i) {
        var cellList = t[i];
        list.add(TableCellList(cellList.cells
            .replaceMore(leftColumn, rightColumn + 1, newCellLists[i].cells)));
      }
      return list;
    });
    return from(newTable, widths);
  }

  bool wholeContain(SingleNodePosition? position) {
    if (position is! SelectingPosition) return false;
    var left = position.left;
    var right = position.right;
    if (left is! TablePosition && right is! TablePosition) {
      return false;
    }
    left = left as TablePosition;
    right = right as TablePosition;
    return left == beginPosition && right == endPosition;
  }

  @override
  Widget build(NodeContext context, NodeBuildParam param, BuildContext c) =>
      RichTable(context, this, param);

  @override
  TablePosition get beginPosition =>
      TablePosition(CellIndex.zero(), firstCell.beginCursor);

  @override
  TablePosition get endPosition => TablePosition(
      CellIndex(rowCount - 1, columnCount - 1), lastCell.endCursor);

  @override
  EditorNode frontPartNode(covariant TablePosition end, {String? newId}) =>
      getFromPosition(beginPosition, end, newId: newId);

  @override
  EditorNode rearPartNode(covariant TablePosition begin, {String? newId}) =>
      getFromPosition(begin, endPosition, newId: newId);

  @override
  EditorNode getFromPosition(
      covariant TablePosition begin, covariant TablePosition end,
      {String? newId}) {
    if (begin == beginPosition && end == endPosition) {
      return from(table, widths, id: newId);
    }
    if (begin == end) {
      return RichTextNode.from([], id: newId ?? id, depth: depth);
    }
    final left = begin.isLowerThan(end) ? begin : end;
    final right = begin.isLowerThan(end) ? end : begin;
    final leftColumn = min(left.column, right.column);
    final rightColumn = max(left.column, right.column);
    if (left.inSameCell(right)) {
      final newWidths = [widths[leftColumn]];
      final cell = getCellByPosition(left);
      if (cell.isBegin(left.cursor) && cell.isEnd(right.cursor)) {
        return from([
          TableCellList([cell])
        ], newWidths, id: newId);
      } else {
        ///TODO:deal with this exception
        throw GetFromPositionButAcquireMoreNodes(
            runtimeType, cell.getNodes(left.cursor, right.cursor), left, right);
      }
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
    } on GetFromPositionButAcquireMoreNodes catch (e) {
      return e.nodes;
    }
  }

  @override
  EditorNode merge(EditorNode other, {String? newId}) {
    if (other is TableNode) {
      var oldTable = List.of(table);
      var newTable = List.of(other.table);
      var mergedTable = <TableCellList>[];
      var mergedWidths = <double>[];
      final diffCount = (columnCount - other.columnCount).abs();
      if (columnCount < other.columnCount) {
        final newNode = insertColumns(
            columnCount - 1,
            List.generate(rowCount, (i) {
              return TableCellList(
                  List.generate(diffCount, (index) => TableCell.empty()));
            }),
            widths.insertMore(widths.length - 1, other.widths));
        mergedTable.addAll(newNode.table);
        mergedTable.addAll(newTable);
      } else if (columnCount > other.columnCount) {
        final newNode = other.insertColumns(
            other.columnCount - 1,
            List.generate(other.rowCount, (i) {
              return TableCellList(
                  List.generate(diffCount, (index) => TableCell.empty()));
            }),
            other.widths.insertMore(other.widths.length - 1, widths));
        mergedTable.addAll(oldTable);
        mergedTable.addAll(newNode.table);
      } else {
        mergedTable.addAll(oldTable);
        mergedTable.addAll(newTable);
      }
      return from(mergedTable, mergedWidths, id: newId);
    } else {
      throw UnableToMergeException('$runtimeType', '${other.runtimeType}');
    }
  }

  @override
  EditorNode newNode({String? id, int? depth}) =>
      from(table, widths, id: id, depth: depth);

  @override
  NodeWithPosition onEdit(EditingData data) {
    final type = data.type;
    final generator = _editingGenerator[type.name];
    if (generator == null) {
      return NodeWithPosition(this, EditingPosition(data.position));
    }
    return generator.call(data.as<TablePosition>(), this);
  }

  @override
  NodeWithPosition onSelect(SelectingData data) {
    final type = data.type;
    final generator = _selectingGenerator[type.name];
    if (generator == null) {
      return NodeWithPosition(
          this, SelectingPosition(data.position.begin, data.position.end));
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
  // EventType.paste.name: (d, n) => pasteWhileEditing(d, n),
  EventType.increaseDepth.name: (d, n) => increaseDepthWhileEditing(d, n),
  EventType.decreaseDepth.name: (d, n) => decreaseDepthWhileEditing(d, n),
};

final _selectingGenerator = <String, _NodeGeneratorWhileSelecting>{
  EventType.delete.name: (d, n) => deleteWhileSelecting(d, n),
  EventType.newline.name: (d, n) => newlineWhileSelecting(d, n),
  EventType.selectAll.name: (d, n) => selectAllWhileSelecting(d, n),
  EventType.typing.name: (d, n) => typingWhileSelecting(d, n),
  // EventType.paste.name: (d, n) => pasteWhileSelecting(d, n),
  EventType.increaseDepth.name: (d, n) => increaseDepthWhileSelecting(d, n),
  EventType.decreaseDepth.name: (d, n) => decreaseDepthWhileSelecting(d, n),
};

typedef _NodeGeneratorWhileEditing = NodeWithPosition Function(
    EditingData<TablePosition> data, TableNode node);

typedef _NodeGeneratorWhileSelecting = NodeWithPosition Function(
    SelectingData<TablePosition> data, TableNode node);

class TableAndWidths {
  final UnmodifiableListView<TableCellList> table;
  final UnmodifiableListView<double> widths;

  TableAndWidths(this.table, this.widths);
}
