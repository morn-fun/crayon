import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/core/copier.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/cursor/table.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:crayon/editor/extension/collection.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/code_block/code_block.dart';
import 'package:crayon/editor/node/rich_text/ordered.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/node/table/table.dart';
import 'package:crayon/editor/node/table/table_cell.dart';
import 'package:crayon/editor/node/table/table_cell_list.dart';
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
    final ctx = buildTextContext([node]);
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

  test('merge', (){

  });
}
