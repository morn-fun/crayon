import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/core/copier.dart';
import 'package:crayon/editor/core/editor_controller.dart';
import 'package:crayon/editor/core/logger.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/code_block.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/cursor/table.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:crayon/editor/exception/menu.dart';
import 'package:crayon/editor/extension/collection.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/code_block/code_block.dart';
import 'package:crayon/editor/node/rich_text/ordered.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/node/rich_text/unordered.dart';
import 'package:crayon/editor/node/table/generator/common.dart';
import 'package:crayon/editor/node/table/table.dart';
import 'package:crayon/editor/node/table/table_cell.dart';
import 'package:crayon/editor/node/table/table_cell_list.dart';
import 'package:crayon/editor/shortcuts/styles.dart';
import 'package:crayon/editor/widget/editor/shared_node_context_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide TableCell;
import 'package:flutter_test/flutter_test.dart';

import '../../config/necessary.dart';

typedef TableCellGenerator = TableCell Function(int row, int column);

typedef NodeGenerator = EditorNode Function(int row, int column, int index);

void main() {
  List<TableCellList> buildCellList(int row, int column, int nodeNum,
      TableCellGenerator? cellGenerator, NodeGenerator? nodeGenerator) {
    List<TableCellList> list = [];
    for (var i = 0; i < row; ++i) {
      List<TableCell> cells = [];
      for (var j = 0; j < column; ++j) {
        final cell = cellGenerator?.call(i, j) ??
            TableCell(List.generate(
                nodeNum,
                (index) =>
                    nodeGenerator?.call(i, j, index) ??
                    RichTextNode.from([RichTextSpan(text: '$i$j$index')])));
        cells.add(cell);
      }
      TableCellList l = TableCellList(cells);
      list.add(l);
    }
    return list;
  }

  TableNode basicNode(
          {int row = 3,
          int column = 4,
          int nodeNum = 5,
          TableCellGenerator? cellGenerator,
          NodeGenerator? nodeGenerator}) =>
      TableNode.from(
          buildCellList(row, column, nodeNum, cellGenerator, nodeGenerator),
          List.generate(column, (i) => 200.0));

  test('newInstance', () {
    final node = basicNode(row: 0, column: 0);
    assert(node.rowCount == 1);
    assert(node.columnCount == 3);
    final n1 = basicNode();
    assert(n1.rowCount == 3);
    assert(n1.columnCount == 4);
  });

  test('row', () {
    final node = basicNode();
    for (var i = 0; i < node.rowCount; ++i) {
      final row = node.row(i);
      for (var j = 0; j < row.length; ++j) {
        final cell = row.getCell(j);
        for (var k = 0; k < cell.length; ++k) {
          final node = cell.getNode(k);
          assert(node.text == '$i$j$k');
        }
      }
    }
  });

  test('column', () {
    final node = basicNode();
    for (var i = 0; i < node.columnCount; ++i) {
      final column = node.column(i);
      for (var j = 0; j < column.length; ++j) {
        final cell = column.getCell(j);
        for (var k = 0; k < cell.length; ++k) {
          final node = cell.getNode(k);
          assert(node.text == '$j$i$k');
        }
      }
    }
  });

  test('getCell', () {
    final node = basicNode();
    for (var i = 0; i < node.rowCount; ++i) {
      final row = node.row(i);
      for (var j = 0; j < row.length; ++j) {
        final cell = row.getCell(j);
        final sameCell = node.getCell(CellPosition(i, j));
        assert(cell == sameCell);
      }
    }
  });

  test('insertRows', () {
    final node = basicNode();
    final n1 = node.insertRows(1, [
      TableCellList(List.generate(
          4,
          (index) => TableCell([
                CodeBlockNode.from(['$index'])
              ]))),
    ]);
    assert(n1.columnCount == 4);
    assert(n1.rowCount == 4);
    final row = n1.row(1);
    for (var j = 0; j < row.length; ++j) {
      final cell = row.getCell(j);
      assert(cell.length == 1);
      var node = cell.first as CodeBlockNode;
      assert(node.codes.length == 1);
      assert(node.codes.first == '$j');
    }
  });

  test('insertColumns', () {
    final node = basicNode();
    final n1 = node.insertColumns(1, [
      ColumnInfo(
          TableCellList(List.generate(
              3,
              (index) => TableCell([
                    CodeBlockNode.from(['$index'])
                  ]))),
          node.initWidth),
    ]);
    assert(n1.columnCount == 5);
    assert(n1.rowCount == 3);
    final column = n1.column(1);
    for (var j = 0; j < column.length; ++j) {
      final cell = column.getCell(j);
      assert(cell.length == 1);
      var node = cell.first as CodeBlockNode;
      assert(node.codes.length == 1);
      assert(node.codes.first == '$j');
    }
  });

  test('removeRows', () {
    final node = basicNode();
    final n1 = node.removeRows(0, 2);
    assert(n1.rowCount == 1);
    assert(n1.columnCount == 4);
    for (var i = 0; i < n1.columnCount; ++i) {
      final cell = n1.getCell(CellPosition(0, i));
      for (var j = 0; j < cell.length; ++j) {
        final node = cell.getNode(j);
        assert(node.text == '2$i$j');
      }
    }

    expect(() => node.removeRows(0, 3),
        throwsA(const TypeMatcher<TableIsEmptyException>()));
  });

  test('removeColumns', () {
    final node = basicNode();
    final n1 = node.removeColumns(1, 3);
    assert(n1.columnCount == 2);
    assert(n1.widths.length == 2);
    final c1 = n1.column(0);
    for (var i = 0; i < c1.length; ++i) {
      final cell = c1.getCell(i);
      for (var j = 0; j < cell.length; ++j) {
        final node = cell.getNode(j);
        assert(node.text == '${i}0$j');
      }
    }
    final c2 = n1.column(1);
    for (var i = 0; i < c2.length; ++i) {
      final cell = c2.getCell(i);
      for (var j = 0; j < cell.length; ++j) {
        final node = cell.getNode(j);
        assert(node.text == '${i}3$j');
      }
    }

    expect(() => node.removeColumns(0, 4),
        throwsA(const TypeMatcher<TableIsEmptyException>()));
  });

  test('updateCell', () {
    final node = basicNode();
    final n1 = node.updateCell(2, 2, to(TableCell.empty(id: 'xxx')));
    assert(n1.rowCount == 3);
    assert(n1.columnCount == 4);
    for (var i = 0; i < n1.rowCount; ++i) {
      final cellList = n1.row(i);
      for (var j = 0; j < cellList.length; ++j) {
        var cell = cellList.getCell(j);
        if (i == 2 && j == 2) {
          assert(cell.length == 1);
          assert(cell.id == 'xxx');
        } else {
          assert(cell.length == 5);
          assert(cell.id != 'xxx');
        }
      }
    }
  });

  test('updateMore', () {
    final node = basicNode();
    final n1 = node.updateMore(CellPosition(1, 2), CellPosition(2, 1), (lists) {
      return lists
          .map((row) => row.updateMore(
              0,
              row.length,
              (cells) => cells
                  .map((cell) => cell.copy(nodes: [CodeBlockNode.from([])]))
                  .toList()))
          .toList();
    });
    assert(n1.rowCount == node.rowCount);
    assert(n1.columnCount == node.columnCount);
    for (var i = 0; i < n1.rowCount; ++i) {
      final cellList = n1.row(i);
      for (var j = 0; j < cellList.length; ++j) {
        var cell = cellList.getCell(j);
        if (1 <= i && i <= 2 && 1 <= j && j <= 2) {
          assert(cell.length == 1);
          assert(cell.first is CodeBlockNode);
        } else {
          assert(cell.length == 5);
        }
      }
    }

    final n2 = node.updateMore(CellPosition(2, 1), CellPosition(1, 2), (lists) {
      return lists
          .map((row) => row.updateMore(
              0,
              row.length,
              (cells) => cells
                  .map((cell) => cell.copy(nodes: [OrderedNode.from([])]))
                  .toList()))
          .toList();
    });
    assert(n2.rowCount == node.rowCount);
    assert(n2.columnCount == node.columnCount);
    for (var i = 0; i < n2.rowCount; ++i) {
      final cellList = n2.row(i);
      for (var j = 0; j < cellList.length; ++j) {
        var cell = cellList.getCell(j);
        if (1 <= i && i <= 2 && 1 <= j && j <= 2) {
          assert(cell.length == 1);
          assert(cell.first is OrderedNode);
        } else {
          assert(cell.length == 5);
        }
      }
    }
  });

  test('wholeContain', () {
    final node = basicNode();
    assert(!node.wholeContain(null));
    assert(!node.wholeContain(EditingCursor(0, RichTextNodePosition.zero())));
    assert(!node.wholeContain(SelectingNodeCursor(
        0, RichTextNodePosition.zero(), RichTextNodePosition.zero())));
    assert(!node.wholeContain(SelectingNodeCursor(
      0,
      TablePosition(
          CellPosition(0, 2), EditingCursor(0, RichTextNodePosition.zero())),
      TablePosition(
          CellPosition(2, 0), EditingCursor(0, RichTextNodePosition.zero())),
    )));
    assert(node.wholeContain(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition)));
    assert(node.wholeContain(SelectingNodeCursor(
      0,
      TablePosition(
          CellPosition(0, 0), EditingCursor(0, RichTextNodePosition.zero())),
      TablePosition(
          CellPosition(2, 3), EditingCursor(4, RichTextNodePosition(0, 3))),
    )));
  });

  test('selectedRows', () {
    final node = basicNode();
    final s1 = node.selectedRows(null);
    assert(s1.isEmpty);
    final s2 = node.selectedRows(EditingCursor(0, RichTextNodePosition.zero()));
    assert(s2.isEmpty);
    final s3 = node.selectedRows(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition));
    assert(s3.equalsTo({0, 1, 2}));

    final s4 = node.selectedRows(SelectingNodeCursor(
        0,
        node.beginPosition.copy(cellPosition: to(CellPosition(0, 0))),
        node.endPosition.copy(cellPosition: to(CellPosition(1, 3)))));
    assert(s4.equalsTo({0, 1}));

    final s5 = node.selectedRows(SelectingNodeCursor(
        0,
        node.beginPosition.copy(cellPosition: to(CellPosition(0, 1))),
        node.endPosition.copy(cellPosition: to(CellPosition(1, 3)))));
    assert(s5.isEmpty);

    final s6 = node.selectedRows(SelectingNodeCursor(
        0, RichTextNodePosition.zero(), RichTextNodePosition.zero()));
    assert(s6.isEmpty);
  });

  test('selectedColumns', () {
    final node = basicNode();
    final s1 = node.selectedColumns(null);
    assert(s1.isEmpty);
    final s2 =
        node.selectedColumns(EditingCursor(0, RichTextNodePosition.zero()));
    assert(s2.isEmpty);
    final s3 = node.selectedColumns(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition));
    assert(s3.equalsTo({0, 1, 2, 3}));

    final s4 = node.selectedColumns(SelectingNodeCursor(
        0,
        node.beginPosition.copy(cellPosition: to(CellPosition(0, 1))),
        node.endPosition.copy(cellPosition: to(CellPosition(2, 2)))));
    assert(s4.equalsTo({1, 2}));

    final s5 = node.selectedColumns(SelectingNodeCursor(
        0,
        node.beginPosition.copy(cellPosition: to(CellPosition(0, 1))),
        node.endPosition.copy(cellPosition: to(CellPosition(1, 2)))));
    assert(s5.isEmpty);

    final s6 = node.selectedColumns(SelectingNodeCursor(
        0, RichTextNodePosition.zero(), RichTextNodePosition.zero()));
    assert(s6.isEmpty);
  });

  test('getCursorInCell', () {
    final node = basicNode();
    final editingCursor = EditingCursor(0, RichTextNodePosition.zero());
    final c1 = node.getCursorInCell(null, CellPosition(0, 0));
    assert(c1 == null);
    final c2 = node.getCursorInCell(
        EditingCursor(0, RichTextNodePosition.zero()), CellPosition(0, 0));
    assert(c2 == null);
    final c3 = node.getCursorInCell(
        EditingCursor(
            0,
            TablePosition(CellPosition(1, 1),
                EditingCursor(0, RichTextNodePosition.zero()))),
        CellPosition(0, 0));
    assert(c3 == null);
    final c4 = node.getCursorInCell(
        EditingCursor(0, TablePosition(CellPosition(0, 0), editingCursor)),
        CellPosition(0, 0));
    assert(c4 == editingCursor);
    final c5 = node.getCursorInCell(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition),
        CellPosition(1, 1));
    assert(c5 == node.getCell(CellPosition(1, 1)).selectAllCursor);
    final c6 = node.getCursorInCell(
        SelectingNodeCursor(0, TablePosition(CellPosition(2, 2), editingCursor),
            node.endPosition),
        CellPosition(1, 1));
    assert(c6 == null);
    final c7 = node.getCursorInCell(
        SelectingNodeCursor(
            0,
            TablePosition(CellPosition(2, 2), editingCursor),
            TablePosition(CellPosition(2, 2),
                EditingCursor(0, RichTextNodePosition(0, 3)))),
        CellPosition(2, 2));
    assert(c7 ==
        SelectingNodeCursor(
            0, RichTextNodePosition.zero(), RichTextNodePosition(0, 3)));
    final c8 = node.getCursorInCell(
        SelectingNodeCursor(
            0,
            TablePosition(CellPosition(2, 2), editingCursor),
            TablePosition(CellPosition(2, 2),
                EditingCursor(2, RichTextNodePosition(0, 3)))),
        CellPosition(2, 2));
    assert(c8 ==
        SelectingNodesCursor(
            editingCursor, EditingCursor(2, RichTextNodePosition(0, 3))));
  });

  testWidgets('build', (tester) async {
    final node = basicNode();
    final ctx = buildEditorContext([node]);
    var widget = ShareEditorContextWidget(
        context: ctx,
        child: Builder(
            builder: (c) => node.build(ctx, NodeBuildParam.empty(), c)));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ));
  });

  test('getFromPosition', () {
    final node = basicNode();
    final n1 =
        node.getFromPosition(node.beginPosition, node.endPosition) as TableNode;
    assert(listEquals(node.table, n1.table));
    assert(listEquals(node.widths, n1.widths));
    assert(n1.id == node.id);

    final n2 = node.getFromPosition(node.beginPosition, node.beginPosition);
    assert(n2 is RichTextNode);
    assert(n2.text.isEmpty);

    final editingCursor = EditingCursor(0, RichTextNodePosition.zero());
    var n3 = node.getFromPosition(
        TablePosition(CellPosition(0, 0), editingCursor),
        TablePosition(CellPosition(2, 2), editingCursor));
    n3 = n3 as TableNode;
    assert(n3.rowCount == 3);
    assert(n3.columnCount == 3);
    for (var i = 0; i < 2; ++i) {
      var cellList = n3.row(i);
      for (var j = 0; j < cellList.length; ++j) {
        var cell = cellList.getCell(j);
        assert(cell.id == node.getCell(CellPosition(i, j)).id);
      }
    }

    final n4 = node.getFromPosition(node.beginPosition,
            node.beginPosition.copy(cursor: to(node.firstCell.endCursor)))
        as TableNode;
    assert(n4.rowCount == 1);
    assert(n4.columnCount == 1);
    assert(n4.firstCell == node.firstCell);

    final n5 = node.getFromPosition(
            node.beginPosition,
            node.beginPosition.copy(
                cursor: to(EditingCursor(3, RichTextNodePosition.zero()))))
        as TableNode;
    assert(n5.rowCount == 1);
    assert(n5.columnCount == 1);
    assert(n5.firstCell.nodes.length == 4);
    assert(n5.firstCell.nodes.last.text.isEmpty);
    assert(n5.firstCell.nodes.first.text == '000');

    final n6 = node.getFromPosition(
            node.beginPosition,
            node.beginPosition
                .copy(cursor: to(EditingCursor(0, RichTextNodePosition(0, 3)))))
        as TableNode;
    assert(n6.rowCount == 1);
    assert(n6.columnCount == 1);
    assert(n6.firstCell.nodes.length == 1);
  });

  test('frontPartNode', () {
    final node = basicNode();
    final n1 = node.frontPartNode(node.endPosition) as TableNode;
    assert(listEquals(node.table, n1.table));
    assert(listEquals(node.widths, n1.widths));
    assert(n1.id == node.id);

    final n2 = node.frontPartNode(node.beginPosition);
    assert(n2 is RichTextNode);
    assert(n2.text.isEmpty);
  });
  test('rearPartNode', () {
    final node = basicNode();
    final n1 = node.rearPartNode(node.beginPosition) as TableNode;
    assert(listEquals(node.table, n1.table));
    assert(listEquals(node.widths, n1.widths));
    assert(n1.id == node.id);

    final n2 = node.rearPartNode(node.endPosition);
    assert(n2 is RichTextNode);
    assert(n2.text.isEmpty);
  });

  test('getInlineNodesFromPosition', () {
    final node = basicNode();
    final list1 =
        node.getInlineNodesFromPosition(node.beginPosition, node.beginPosition);
    assert(list1.length == 1);
    assert(list1.first is RichTextNode);
    assert(list1.first.text.isEmpty);

    final list2 = node.getInlineNodesFromPosition(node.beginPosition,
        node.beginPosition.copy(cursor: to(node.firstCell.endCursor)));
    assert(list2.length == 5);

    final list3 =
        node.getInlineNodesFromPosition(node.beginPosition, node.endPosition);
    assert(list3.length == 3 * 4 * 5);

    final list4 = node.getInlineNodesFromPosition(
        node.beginPosition,
        node.beginPosition
            .copy(cursor: to(EditingCursor(3, RichTextNodePosition.zero()))));
    assert(list4.length == 4);
  });

  test('merge', () {
    final node = basicNode();
    expect(() => node.merge(RichTextNode.from([])),
        throwsA(const TypeMatcher<UnableToMergeException>()));
    final node2 = basicNode(
        row: 1,
        column: 1,
        nodeNum: 1,
        nodeGenerator: (r, c, i) => CodeBlockNode.from([], id: 'xxx'));
    final n1 = node.merge(node2) as TableNode;
    assert(n1.rowCount == 4);
    assert(n1.columnCount == 4);
    final cell1 = n1.getCell(CellPosition(3, 0));
    assert(cell1.length == 1);
    assert(cell1.first is CodeBlockNode);
    assert(cell1.first.id == 'xxx');

    final node3 = basicNode(
        row: 2,
        column: 5,
        nodeNum: 1,
        nodeGenerator: (r, c, i) => CodeBlockNode.from([], id: 'yyy'));
    final n2 = node.merge(node3) as TableNode;
    assert(n2.rowCount == 5);
    assert(n2.columnCount == 5);
    var cell2 = n2.getCell(CellPosition(3, 0));
    assert(cell2.length == 1);
    assert(cell2.first is CodeBlockNode);
    assert(cell2.first.id == 'yyy');
    cell2 = n2.getCell(CellPosition(4, 0));
    assert(cell2.length == 1);
    assert(cell2.first is CodeBlockNode);
    assert(cell2.first.id == 'yyy');

    final node4 = basicNode(
        nodeGenerator: (r, c, i) => CodeBlockNode.from([], id: 'zzz'));
    final n3 = node.merge(node4) as TableNode;
    assert(n3.rowCount == 6);
    assert(n3.columnCount == 4);
    var cell3 = n3.getCell(CellPosition(4, 0));
    assert(cell3.length == 5);
    assert(cell3.first is CodeBlockNode);
    assert(cell3.first.id == 'zzz');
    assert(cell3.last.id == 'zzz');
  });

  test('newNode', () {
    final node = basicNode();
    final n1 = node.newNode(id: 'xxx') as TableNode;
    assert(n1.id == 'xxx');
    assert(n1.id != node.id);
    assert(listEquals(n1.table, node.table));

    final n2 = node.newNode(depth: 2) as TableNode;
    assert(n2.depth == 2);
    assert(n2.id == node.id);
    assert(n2.depth != node.depth);
    assert(listEquals(n2.table, node.table));

    final n3 = node.newNode(id: 'yyy', depth: 10) as TableNode;
    assert(n3.depth != node.depth);
    assert(n3.id != node.id);
    assert(n3.depth == 10);
    assert(n3.id == 'yyy');
    assert(listEquals(n3.table, node.table));
  });

  test('text', () {
    final node = basicNode();
    final text = node.text;
    assert(text == node.table.map((e) => e.text).join('\n'));
  });

  test('toJson', () {
    final node = basicNode();
    final json = node.toJson();
    assert(json['type'] == '${node.runtimeType}');
    final List<Map<String, dynamic>> table = json['table'];
    for (var i = 0; i < node.rowCount; ++i) {
      final cellList = node.row(i);
      assert(cellList.toJson().toString() == table[i].toString());
    }
  });

  test('onEdit-delete', () {
    final node = basicNode(
        row: 1,
        column: 1,
        nodeNum: 1,
        nodeGenerator: (r, c, i) => RichTextNode.from([
              RichTextSpan(
                text: 'aaa',
              )
            ], id: 'xxx'));
    final ctx = buildEditorContext([node]);

    try {
      node.onEdit(
          EditingData(node.endPosition.toCursor(0), EventType.delete, ctx));
    } on NodeUnsupportedException {
      final n1 = ctx.nodes.first as TableNode;
      final innerN1 = n1.firstCell.first;
      assert(innerN1.id == 'xxx');
      assert(innerN1.text == 'aa');
      assert(ctx.cursor == EditingCursor(0, n1.endPosition));
    }
  });

  test('onSelect-delete', () {
    var node = basicNode(
        row: 1,
        column: 1,
        nodeNum: 1,
        nodeGenerator: (r, c, i) =>
            RichTextNode.from([RichTextSpan(text: 'aaabbb')]));
    var ctx = buildEditorContext([node]);
    final r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition),
        EventType.delete,
        ctx));
    assert(r1.node is RichTextNode);
    assert(r1.node.text.isEmpty);
    assert(r1.cursor == EditingCursor(0, RichTextNodePosition.zero()));

    try {
      ctx = buildEditorContext([node]);
      node.onSelect(SelectingData(
          SelectingNodeCursor(
              0,
              node.endPosition.copy(
                  cursor: to(EditingCursor(0, RichTextNodePosition(0, 3)))),
              node.endPosition),
          EventType.delete,
          ctx));
    } on NodeUnsupportedException {
      final n = ctx.nodes.first as TableNode;
      final innerN1 = n.firstCell.first;
      assert(innerN1.text == 'aaa');
      assert(ctx.cursor == EditingCursor(0, n.endPosition));
    }

    try {
      node = basicNode();
      ctx = buildEditorContext([node]);
      node.onSelect(SelectingData(
          SelectingNodeCursor(
              0,
              node.endPosition.copy(
                  cursor: to(EditingCursor(0, RichTextNodePosition(0, 1)))),
              node.endPosition),
          EventType.delete,
          ctx));
    } on NodeUnsupportedException {
      final n = ctx.nodes.first as TableNode;
      final innerN1 = n.lastCell.first;
      assert(innerN1.text.length == 1);
      assert(ctx.cursor == EditingCursor(0, n.endPosition));
    }

    node = basicNode();
    ctx = buildEditorContext([node]);
    final r2 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, node.beginPosition,
            node.beginPosition.copy(cellPosition: to(CellPosition(1, 1)))),
        EventType.delete,
        ctx));
    final n2 = r2.node as TableNode;
    var c2 = (r2.cursor as SelectingNodeCursor).as<TablePosition>();
    assert(c2.left.cellPosition == CellPosition(0, 0));
    assert(c2.right.cellPosition == CellPosition(1, 1));
    assert(node.rowCount == n2.rowCount);
    assert(node.columnCount == n2.columnCount);
    for (var i = 0; i < 2; ++i) {
      var cellList = n2.row(i);
      for (var j = 0; j < 2; ++j) {
        var cell = cellList.getCell(j);
        assert(cell.length == 1);
        assert(cell.first is RichTextNode);
        assert(cell.first.text.isEmpty);
      }
    }

    node = basicNode();
    ctx = buildEditorContext([node]);
    final r3 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, node.beginPosition,
            node.beginPosition.copy(cursor: to(node.firstCell.endCursor))),
        EventType.delete,
        ctx));
    final n3 = r3.node as TableNode;
    final c3 = (r3.cursor as EditingCursor).as<TablePosition>();
    assert(n3.firstCell.length == 1);
    assert(c3.position.cellPosition == CellPosition(0, 0));
  });

  test('onEdit-depth', () {
    var node = basicNode(
            row: 1,
            column: 1,
            nodeNum: 1,
            nodeGenerator: (r, c, i) => RichTextNode.from([
                  RichTextSpan(
                    text: 'aaa',
                  )
                ], id: 'xxx')),
        ctx = buildEditorContext([node]);
    try {
      node.onEdit(EditingData(
          node.beginPosition.toCursor(0), EventType.increaseDepth, ctx));
    } on NodeUnsupportedException {
      final n1 = ctx.nodes.first as TableNode;
      final innerN1 = n1.firstCell.first;
      assert(innerN1.id == 'xxx');
      assert(innerN1.text == 'aaa');
      assert(ctx.cursor == EditingCursor(0, n1.beginPosition));
      assert(innerN1.depth == 1);
    }

    node = basicNode(
        row: 1,
        column: 1,
        nodeNum: 1,
        nodeGenerator: (r, c, i) => RichTextNode.from([
              RichTextSpan(
                text: 'bbb',
              )
            ], id: 'yyy', depth: 100));
    ctx = buildEditorContext([node]);
    try {
      node.onEdit(EditingData(
          node.beginPosition.toCursor(0), EventType.decreaseDepth, ctx));
    } on NodeUnsupportedException {
      final n1 = ctx.nodes.first as TableNode;
      final innerN1 = n1.firstCell.first;
      assert(innerN1.id == 'yyy');
      assert(innerN1.text == 'bbb');
      assert(ctx.cursor == EditingCursor(0, n1.beginPosition));
      assert(innerN1.depth == 99);
    }
  });

  test('onSelect-depth', () {
    var node = basicNode();
    var ctx = buildEditorContext([node]);
    final r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition),
        EventType.increaseDepth,
        ctx));
    assert(r1.node.depth == 1);

    expect(
        () => node.newNode(depth: 100).onSelect(SelectingData(
            SelectingNodeCursor(0, node.beginPosition, node.endPosition),
            EventType.increaseDepth,
            ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));

    try {
      node = basicNode();
      ctx = buildEditorContext([node]);
      node.onSelect(SelectingData(
          SelectingNodeCursor(
              0,
              node.beginPosition,
              node.beginPosition.copy(
                  cursor: to(EditingCursor(0, RichTextNodePosition(0, 2))))),
          EventType.increaseDepth,
          ctx));
    } on NodeUnsupportedException {
      final n1 = ctx.nodes.first as TableNode;
      final innerN1 = n1.firstCell.first;
      assert(innerN1.depth == 1);
    }

    try {
      node = basicNode();
      ctx = buildEditorContext([node]);
      node.onSelect(SelectingData(
          SelectingNodeCursor(
              0,
              node.beginPosition,
              node.beginPosition.copy(
                  cursor: to(EditingCursor(1, RichTextNodePosition(0, 2))))),
          EventType.increaseDepth,
          ctx));
    } on NodeUnsupportedException {
      final n1 = ctx.nodes.first as TableNode;
      final innerN1 = n1.firstCell.first;
      assert(innerN1.depth == 1);
      assert(n1.firstCell.getNode(1).depth == 1);
      assert(n1.firstCell.getNode(2).depth == 0);
    }

    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(0, node.beginPosition, node.endPosition),
            EventType.decreaseDepth,
            ctx)),
        throwsA(const TypeMatcher<DepthNeedDecreaseMoreException>()));

    try {
      node = basicNode(
          nodeGenerator: (r, c, i) => RichTextNode.from([], depth: 1));
      ctx = buildEditorContext([node]);
      node.onSelect(SelectingData(
          SelectingNodeCursor(
              0,
              node.beginPosition,
              node.beginPosition.copy(
                  cursor: to(EditingCursor(0, RichTextNodePosition(0, 3))))),
          EventType.decreaseDepth,
          ctx));
    } on NodeUnsupportedException {
      final n1 = ctx.nodes.first as TableNode;
      assert(n1.firstCell.getNode(0).depth == 0);
      assert(n1.firstCell.getNode(1).depth == 1);
      assert(n1.firstCell.getNode(2).depth == 1);
    }

    try {
      node = basicNode(
          nodeGenerator: (r, c, i) => RichTextNode.from([], depth: 1));
      ctx = buildEditorContext([node]);
      node.onSelect(SelectingData(
          SelectingNodeCursor(
              0,
              node.beginPosition,
              node.beginPosition.copy(
                  cursor: to(EditingCursor(1, RichTextNodePosition(0, 2))))),
          EventType.decreaseDepth,
          ctx));
    } on NodeUnsupportedException {
      final n1 = ctx.nodes.first as TableNode;
      assert(n1.firstCell.getNode(0).depth == 0);
      assert(n1.firstCell.getNode(1).depth == 0);
      assert(n1.firstCell.getNode(2).depth == 1);
    }
  });

  test('onEdit-newline', () {
    var node = basicNode(), ctx = buildEditorContext([node]);
    try {
      node.onEdit(
          EditingData(node.beginPosition.toCursor(0), EventType.newline, ctx));
    } on NodeUnsupportedException {
      final n1 = ctx.nodes.first as TableNode;
      final firstCell = n1.firstCell;
      assert(firstCell.length == 6);
      assert(firstCell.first.text.isEmpty);
      assert(firstCell.getNode(1).text.isNotEmpty);
    }
  });

  test('onSelect-newline', () {
    var node = basicNode(), ctx = buildEditorContext([node]);
    try {
      node.onSelect(SelectingData(
          SelectingNodeCursor(
              0,
              node.beginPosition,
              node.beginPosition.copy(
                  cursor: to(EditingCursor(0, RichTextNodePosition(0, 2))))),
          EventType.newline,
          ctx));
    } on NodeUnsupportedException {
      final n1 = ctx.nodes.first as TableNode;
      final firstCell = n1.firstCell;
      assert(firstCell.length == 6);
      assert(firstCell.first.text.isEmpty);
      assert(firstCell.getNode(1).text == '0');
    }

    node = basicNode();
    ctx = buildEditorContext([node]);
    try {
      node.onSelect(SelectingData(
          SelectingNodeCursor(
              0,
              node.beginPosition,
              node.beginPosition.copy(
                  cursor: to(EditingCursor(2, RichTextNodePosition(0, 2))))),
          EventType.newline,
          ctx));
    } on NodeUnsupportedException {
      final n1 = ctx.nodes.first as TableNode;
      final firstCell = n1.firstCell;
      assert(firstCell.length == 4);
      assert(firstCell.first.text.isEmpty);
      assert(firstCell.getNode(1).text == '2');
    }
  });

  test('onEdit-selectAll', () {
    var node = basicNode(), ctx = buildEditorContext([node]);
    try {
      node.onEdit(EditingData(
          node.beginPosition.toCursor(0), EventType.selectAll, ctx));
    } on NodeUnsupportedException {
      assert(ctx.cursor ==
          SelectingNodeCursor(
              0,
              node.beginPosition,
              node.beginPosition.copy(
                  cursor: to(node.firstCell.first.endPosition.toCursor(0)))));
    }
  });

  test('onSelect-selectAll', () {
    var node = basicNode(), ctx = buildEditorContext([node]);
    final r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(
            0,
            node.beginPosition,
            node.beginPosition.copy(
                cursor: to(EditingCursor(0, RichTextNodePosition(0, 1))))),
        EventType.selectAll,
        ctx));
    final c1 = (r1.cursor as SelectingNodeCursor).as<TablePosition>();
    assert(c1 ==
        SelectingNodeCursor(
            0,
            node.beginPosition,
            node.beginPosition.copy(
                cursor:
                    to(EditingCursor(0, node.firstCell.first.endPosition)))));

    final r2 = node.onSelect(SelectingData(
        SelectingNodeCursor(
            0,
            node.beginPosition,
            node.beginPosition.copy(
                cursor: to(EditingCursor(2, RichTextNodePosition(0, 1))))),
        EventType.selectAll,
        ctx));
    final c2 = (r2.cursor as SelectingNodeCursor).as<TablePosition>();
    assert(c2 ==
        SelectingNodeCursor(0, node.beginPosition,
            node.beginPosition.copy(cursor: to(node.firstCell.endCursor))));

    final r3 = node.onSelect(SelectingData(c2, EventType.selectAll, ctx));
    final c3 = (r3.cursor as SelectingNodeCursor).as<TablePosition>();
    assert(c3.left == node.beginPosition);
    assert(c3.right == node.endPosition);
  });

  test('onEdit-style', () {
    var node = basicNode(), ctx = buildEditorContext([node]);
    expect(
        () => node.onEdit(
            EditingData(node.endPosition.toCursor(0), EventType.bold, ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
  });

  test('onSelect-style', () {
    var node = basicNode(), ctx = buildEditorContext([node]);
    final cursor = SelectingNodeCursor(
        0,
        node.beginPosition
            .copy(cursor: to(EditingCursor(0, RichTextNodePosition(0, 1)))),
        node.beginPosition
            .copy(cursor: to(EditingCursor(0, RichTextNodePosition(0, 2)))));
    try {
      node.onSelect(SelectingData(cursor, EventType.bold, ctx));
    } on NodeUnsupportedException catch (e) {
      logger.e('$e');
    }
    final n1 = ctx.nodes.first as TableNode;
    final c1 = (ctx.cursor as SelectingNodeCursor).as<TablePosition>();
    final innerN1 = n1.firstCell.first as RichTextNode;
    assert(innerN1.spans.length == 3);
    assert(innerN1.spans[0].tags.isEmpty);
    assert(innerN1.spans[1].tags.equalsTo({'bold'}));
    assert(innerN1.spans[0].tags.isEmpty);

    try {
      n1.onSelect(SelectingData(c1, EventType.bold, ctx,
          extras: StyleExtra(true, null)));
    } on NodeUnsupportedException catch (e) {
      logger.e('$e');
    }

    final n2 = ctx.nodes.first as TableNode;
    final c2 = (ctx.cursor as SelectingNodeCursor).as<TablePosition>();
    final innerN2 = n2.firstCell.first as RichTextNode;
    assert(innerN2.spans.length == 1);
    assert(innerN2.spans.first.tags.isEmpty);
    assert(innerN2.spans.first.text == '000');
    assert(c2 == cursor);

    final cursor2 = SelectingNodeCursor(0, node.beginPosition,
        node.beginPosition.copy(cellPosition: to(CellPosition(1, 1))));
    final r3 = n2
        .updateCell(0, 0, (t) => t.update(2, to(CodeBlockNode.from([]))))
        .onSelect(SelectingData(cursor2, EventType.bold, ctx));

    final n3 = r3.node as TableNode;
    final c3 = (r3.cursor as SelectingNodeCursor).as<TablePosition>();
    for (var i = 0; i < n3.rowCount; ++i) {
      final cellList = n3.row(i);
      for (var j = 0; j < cellList.length; ++j) {
        final cell = cellList.getCell(j);
        for (var k = 0; k < cell.length; ++k) {
          final node = cell.getNode(k);
          if (node is! RichTextNode) continue;
          bool isBold = true;
          int l = 0;
          while (l < node.spans.length && isBold) {
            final span = node.spans[l];
            if (!span.tags.contains('bold')) {
              isBold = false;
            }
            l++;
          }
          if (i < 2 && j < 2) {
            assert(isBold);
          } else {
            assert(!isBold);
          }
        }
      }
    }

    assert(c3 ==
        SelectingNodeCursor(
            0,
            TablePosition(CellPosition(0, 0), node.firstCell.beginCursor),
            TablePosition(CellPosition(1, 1),
                node.getCell(CellPosition(1, 1)).endCursor)));
  });

  test('onEdit-typing', () {
    var node = basicNode(
            nodeGenerator: (r, c, i) =>
                RichTextNode.from([RichTextSpan(text: '-$r$c$i')])),
        ctx = buildEditorContext([node]);
    final r1 = node.onEdit(EditingData(
        EditingCursor(
            0,
            TablePosition(CellPosition(0, 0),
                EditingCursor(0, RichTextNodePosition(0, 1)))),
        EventType.typing,
        ctx,
        extras: TextEditingValue(
            text: ' ', selection: TextSelection.collapsed(offset: 1))));
    final n1 = r1.node as TableNode;
    final c1 = (r1.cursor as EditingCursor).as<TablePosition>();
    assert(n1.firstCell.first is UnorderedNode);
    assert(c1.position == n1.beginPosition);

    expect(
        () => node.onEdit(EditingData(
            node.beginPosition.toCursor(0), EventType.typing, ctx,
            extras: TextEditingValue(
                text: '/', selection: TextSelection.collapsed(offset: 1)))),
        throwsA(const TypeMatcher<TypingRequiredOptionalMenuException>()));

    expect(
        () => node.onEdit(
            EditingData(node.beginPosition.toCursor(0), EventType.typing, ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));

    final r2 = node.onEdit(EditingData(
        node.beginPosition.toCursor(0), EventType.typing, ctx,
        extras: TextEditingValue(
            text: ' ', selection: TextSelection.collapsed(offset: 1))));
    final n2 = r2.node as TableNode;
    final c2 = (r2.cursor as EditingCursor).as<TablePosition>();
    assert(n2.firstCell.first is RichTextNode);
    assert(n2.firstCell.first.text == ' -000');
    assert(c2.position ==
        n2.beginPosition
            .copy(cursor: to(EditingCursor(0, RichTextNodePosition(0, 1)))));
  });

  test('onSelect-typing', () {
    var node = basicNode(
            nodeGenerator: (r, c, i) =>
                RichTextNode.from([RichTextSpan(text: '-$r$c$i')])),
        ctx = buildEditorContext([node]);

    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(0, node.beginPosition, node.endPosition),
            EventType.typing,
            ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
  });

  test('others', () {
    var node = basicNode(), ctx = buildEditorContext([node]);
    final cellContext = buildTableCellNodeContext(
        ctx, CellPosition(0, 0), node, NoneCursor(), 0);
    cellContext.onEditingOffset(EditingOffset(Offset.zero, 18, ''));
    cellContext.onNode(RichTextNode.from([]), 0);
    cellContext.onPanUpdate(EditingCursor(0, RichTextNodePosition.zero()));

    expect(() => cellContext.onCursor(NoneCursor()),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));

    final cellCursor = buildTableCellCursor(
        TableCell([
          CodeBlockNode.from(['aaa']),
          CodeBlockNode.from(['bbb']),
          CodeBlockNode.from(['ccc']),
        ]),
        EditingCursor(0, CodeBlockPosition.zero()),
        EditingCursor(2, CodeBlockPosition.zero())) as SelectingNodesCursor;
    assert(cellCursor.left == CodeBlockPosition.zero(atEdge: true).toCursor(0));
    assert(cellCursor.right ==
        CodeBlockPosition(0, 3, atEdge: true).toCursor(2));
  });
}
