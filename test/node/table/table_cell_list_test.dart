import 'package:crayon/editor/core/copier.dart';
import 'package:crayon/editor/node/code_block/code_block.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/table/table_cell.dart';
import 'package:crayon/editor/node/table/table_cell_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('insert', () {
    final list = TableCellList.empty();
    assert(list.length == 3);
    final l1 = list.insert(1, [TableCell.empty(id: '111')]);
    assert(l1.length == 4);
    assert(l1.getCell(1).id == '111');

    final l2 = list.insert(0, [
      TableCell.empty(id: 'xxx'),
      TableCell.empty(id: 'yyy'),
    ]);
    assert(l2.getCell(0).id == 'xxx');
    assert(l2.getCell(1).id == 'yyy');
    for (var i = 2; i < l2.length; ++i) {
      var cell = l2.getCell(i);
      assert(cell.id == list.getCell(i - 2).id);
    }
  });

  test('replace', () {
    final list = TableCellList.empty();
    final l1 = list.replace(0, 1, [TableCell.empty(id: '111')]);
    assert(l1.length == 3);
    assert(l1.getCell(0).id == '111');

    var l2 = list.replace(1, 3, [
      TableCell.empty(id: 'xxx'),
      TableCell.empty(id: 'yyy'),
    ]);
    assert(l2.length == 3);
    assert(l2.getCell(0).id == list.getCell(0).id);
    assert(l2.getCell(1).id == 'xxx');
    assert(l2.getCell(2).id == 'yyy');
  });

  test('update', () {
    final list = TableCellList([], initNum: 5);
    final l1 =
        list.update(0, to(TableCell([CodeBlockNode.from([])], id: 'aaa')));
    assert(l1.length == 5);
    assert(l1.first.id == 'aaa');
    assert(l1.first.first is CodeBlockNode);
  });

  test('updateMore', () {
    final list = TableCellList([], initNum: 5);
    final l1 = list.updateMore(1, 4, (v) {
      return v
          .map((e) => e.copy(nodes: [
                CodeBlockNode.from([''])
              ]))
          .toList();
    });
    assert(l1.length == 5);
    assert(l1.first.first is RichTextNode);
    for (var i = 1; i < 4; ++i) {
      var cell = l1.getCell(i);
      assert(cell.first is CodeBlockNode);
    }
    assert(l1.last.first is RichTextNode);
  });

  test('toJson', () {
    final list = TableCellList([
      TableCell([
        CodeBlockNode.from(['aaa'])
      ]),
      TableCell([
        CodeBlockNode.from(['bbb'])
      ]),
      TableCell([
        CodeBlockNode.from(['ccc'])
      ]),
    ]);

    final json = list.toJson();
    assert(json['type'] == '${list.runtimeType}');
    final cells = json['cells'] as List<Map<String, dynamic>>;
    for (var i = 0; i < cells.length; ++i) {
      var jsonCell = cells[i];
      var cell = list.getCell(i);
      assert(jsonCell.toString() == cell.toJson().toString());
    }
  });

  test('text', () {
    final list = TableCellList([
      TableCell([
        CodeBlockNode.from(['aaa'])
      ]),
      TableCell([
        CodeBlockNode.from(['bbb'])
      ]),
      TableCell([
        CodeBlockNode.from(['ccc'])
      ]),
    ]);

    final text = list.text;
    assert(text == list.cells.map((e) => e.text).join(' | '));
  });
}
