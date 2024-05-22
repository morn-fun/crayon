import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart' hide RichText, TableCell;

import '../../../../editor/extension/unmodifiable.dart';
import '../../../../editor/node/rich_text/rich_text.dart';
import '../../core/context.dart';
import '../../core/copier.dart';
import '../../core/editor_controller.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic.dart';
import '../../cursor/table.dart';
import '../../exception/editor_node.dart';
import '../../widget/nodes/table.dart';
import '../basic.dart';
import '../rich_text/rich_text_span.dart';
import 'generator/deletion.dart';
import 'generator/depth.dart';
import 'generator/newline.dart';
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

  TableCell getCell(CellPosition p) => table[p.row].getCell(p.column);

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

  TableNode removeRows(int begin, int end) {
    final newTable = table.replaceMore(begin, end, []);
    if (newTable.isEmpty) throw TableIsEmptyException();
    return from(newTable, widths);
  }

  TableNode removeColumns(int begin, int end) {
    final newWidths = widths.replaceMore(begin, end, []);
    List<TableCellList> newTable = [];
    for (var cellList in table) {
      final list = cellList.replace(begin, end, []);
      if (list.length == 0) throw TableIsEmptyException();
      newTable.add(list);
    }
    if (newTable.isEmpty) throw TableIsEmptyException();
    return from(newTable, newWidths);
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
    assert(!begin.sameCell(end));
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

  bool wholeContain(SingleNodeCursor? cursor) {
    if (cursor is! SelectingNodeCursor) return false;
    try {
      var left = cursor.left;
      var right = cursor.right;
      return left == beginPosition && right == endPosition;
    } on TypeError {
      return false;
    }
  }

  int? wholeContainsRow(SingleNodeCursor? cursor) {
    if (cursor is! SelectingNodeCursor) return null;
    try {
      final p = cursor.as<TablePosition>();
      final lp = p.left.cellPosition;
      final rp = p.right.cellPosition;
      final sameRow = lp.row == rp.row;
      final wholeColumn =
          lp.column == 0 && rp.column == table[rp.row].length - 1;
      return (sameRow && wholeColumn) ? lp.row : null;
    } on TypeError {
      return null;
    }
  }

  int? wholeContainsColumn(SingleNodeCursor? cursor) {
    if (cursor is! SelectingNodeCursor) return null;
    try {
      final p = cursor.as<TablePosition>();
      final lp = p.left.cellPosition;
      final rp = p.right.cellPosition;
      final sameColumn = lp.column == rp.column;
      final wholeRow = lp.row == 0 && rp.row == table.length - 1;
      return (sameColumn && wholeRow) ? lp.column : null;
    } on TypeError {
      return null;
    }
  }

  BasicCursor? getCursor(SingleNodeCursor? cursor, CellPosition cellPosition) {
    final c = cursor;
    if (c == null) return null;
    if (c is EditingCursor) {
      final editingCursor = c.as<TablePosition>();
      if (editingCursor.position.cellPosition == cellPosition) {
        return editingCursor.position.cursor;
      }
      return null;
    }
    if (c is SelectingNodeCursor) {
      final selectingCursor = c.as<TablePosition>();
      final left = selectingCursor.left;
      final right = selectingCursor.right;
      bool containsSelf =
          cellPosition.containSelf(left.cellPosition, right.cellPosition);
      if (!containsSelf) return null;
      if (left.sameCell(right)) {
        final sameIndex = left.index == right.index;
        if (sameIndex) {
          return SelectingNodeCursor(left.index, left.position, right.position);
        }
        return SelectingNodesCursor(left.cursor, right.cursor);
      }
      return getCell(cellPosition).selectAllCursor;
    }
    return null;
  }

  TableCellNodeContext buildContext({
    required CellPosition position,
    required BasicCursor cursor,
    required ListenerCollection listeners,
    required ValueChanged<Replace> onReplace,
    required ValueChanged<Update> onUpdate,
    required ValueChanged<BasicCursor> onBasicCursor,
    required ValueChanged<EditingOffset> editingOffset,
    required ValueChanged<EditingCursor> onPan,
    required ValueChanged<NodeWithIndex> onNodeUpdate,
  }) {
    final cell = getCell(position);
    final childListener =
        listeners.getListener(cell.id) ?? ListenerCollection();
    return TableCellNodeContext(
        cellGetter: () => cell,
        cursorGetter: () => cursor,
        onReplace: onReplace,
        onUpdate: onUpdate,
        onBasicCursor: onBasicCursor,
        editingOffset: editingOffset,
        onPan: onPan,
        onNodeUpdate: onNodeUpdate,
        listeners: childListener);
  }

  @override
  Widget build(NodeContext context, NodeBuildParam param, BuildContext c) =>
      RichTable(context, this, param);

  @override
  TablePosition get beginPosition =>
      TablePosition(CellPosition.zero(), firstCell.beginCursor);

  @override
  TablePosition get endPosition => TablePosition(
      CellPosition(rowCount - 1, columnCount - 1), lastCell.endCursor);

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
    if (left.sameCell(right)) {
      final newWidths = [widths[leftColumn]];
      final cell = getCell(left.cellPosition);
      final sameIndex = left.index == right.index;
      BasicCursor cursor = sameIndex
          ? SelectingNodeCursor(left.index, left.position, right.position)
          : SelectingNodesCursor(left.cursor, right.cursor);
      if (cell.wholeSelected(cursor)) {
        return from([
          TableCellList([cell])
        ], newWidths, id: newId);
      } else {
        return from([
          TableCellList([TableCell(cell.getNodes(left.cursor, right.cursor))])
        ], newWidths, id: newId);
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
