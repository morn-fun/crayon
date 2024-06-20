import 'package:crayon/editor/core/copier.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/code_block.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/code_block/code_block.dart';
import 'package:crayon/editor/node/rich_text/head.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/node/table/table_cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TableCell basicCell({
    List<EditorNode>? nodes,
  }) =>
      nodes == null ? TableCell.empty() : TableCell(nodes);

  test('selectAllCursor', () {
    final cell = basicCell();
    final c1 = cell.selectAllCursor;
    assert(c1 is SelectingNodeCursor);

    final cell2 = basicCell(nodes: [
      RichTextNode.from([]),
      RichTextNode.from([]),
      RichTextNode.from([]),
    ]);
    var c2 = cell2.selectAllCursor;
    c2 = c2 as SelectingNodesCursor;
    assert(c2.left.index == 0);
    assert(c2.right.index == 2);
  });

  test('clear', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([]),
      RichTextNode.from([]),
      RichTextNode.from([]),
    ]);
    assert(cell.length == 3);
    final cell2 = cell.clear();
    assert(cell2.length == 1);
  });

  test('isBegin', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([]),
      RichTextNode.from([]),
      RichTextNode.from([]),
    ]);
    assert(cell.isBegin(EditingCursor(0, RichTextNodePosition.zero())));
    assert(!cell.isBegin(EditingCursor(1, RichTextNodePosition.zero())));
    assert(!cell.isBegin(EditingCursor(2, RichTextNodePosition.zero())));

    final cell2 = basicCell(nodes: [
      CodeBlockNode.from(['111', '222']),
      RichTextNode.from([]),
      RichTextNode.from([]),
    ]);
    assert(
        cell2.isBegin(EditingCursor(0, CodeBlockPosition.zero(atEdge: true))));
    assert(!cell2
        .isBegin(EditingCursor(0, CodeBlockPosition.zero(atEdge: false))));
    assert(!cell2.isBegin(EditingCursor(1, RichTextNodePosition.zero())));
    assert(!cell2.isBegin(EditingCursor(2, RichTextNodePosition.zero())));
  });

  test('isEnd', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([RichTextSpan(text: '111')]),
      RichTextNode.from([RichTextSpan(text: '222')]),
      RichTextNode.from([RichTextSpan(text: '333')]),
    ]);
    assert(!cell.isEnd(EditingCursor(0, RichTextNodePosition.zero())));
    assert(!cell.isEnd(EditingCursor(1, RichTextNodePosition.zero())));
    assert(!cell.isEnd(EditingCursor(2, RichTextNodePosition.zero())));
    assert(cell.isEnd(EditingCursor(2, RichTextNodePosition(0, 3))));

    final cell2 = basicCell(nodes: [
      RichTextNode.from([]),
      RichTextNode.from([]),
      CodeBlockNode.from(['111', '222']),
    ]);
    assert(
        !cell2.isEnd(EditingCursor(0, CodeBlockPosition.zero(atEdge: true))));
    assert(!cell2.isEnd(EditingCursor(1, RichTextNodePosition.zero())));
    assert(!cell2.isEnd(EditingCursor(2, RichTextNodePosition.zero())));
    assert(
        !cell2.isEnd(EditingCursor(2, CodeBlockPosition(1, 3, atEdge: false))));
    assert(
        cell2.isEnd(EditingCursor(2, CodeBlockPosition(1, 3, atEdge: true))));
  });

  test('wholeSelected', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([RichTextSpan(text: '111')]),
      RichTextNode.from([RichTextSpan(text: '222')]),
      RichTextNode.from([RichTextSpan(text: '333')]),
      CodeBlockNode.from(['444', '555']),
    ]);
    assert(!cell.wholeSelected(null));
    assert(!cell.wholeSelected(EditingCursor(0, RichTextNodePosition.zero())));
    assert(!cell.wholeSelected(SelectingNodeCursor(
        0, RichTextNodePosition.zero(), RichTextNodePosition(0, 3))));
    assert(!cell.wholeSelected(SelectingNodesCursor(
      EditingCursor(0, RichTextNodePosition.zero()),
      EditingCursor(3, CodeBlockPosition(1, 3, atEdge: false)),
    )));
    assert(cell.wholeSelected(SelectingNodesCursor(
      EditingCursor(0, RichTextNodePosition.zero()),
      EditingCursor(3, CodeBlockPosition(1, 3, atEdge: true)),
    )));

    final cell2 = basicCell(nodes: [
      CodeBlockNode.from(['111', '222']),
    ]);
    assert(cell2.wholeSelected(SelectingNodeCursor(
        0,
        CodeBlockPosition.zero(atEdge: true),
        CodeBlockPosition(1, 3, atEdge: true))));
  });

  test('update', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([RichTextSpan(text: '111')]),
      RichTextNode.from([RichTextSpan(text: '222')]),
      RichTextNode.from([RichTextSpan(text: '333')]),
      CodeBlockNode.from(['444', '555']),
    ]);
    var ce1 =
        cell.update(0, to(RichTextNode.from([RichTextSpan(text: 'aaa')])));
    assert(ce1.first is RichTextNode);
    assert(ce1.first.text == 'aaa');
    assert(ce1.getNode(1).text == '222');
    assert(ce1.getNode(2).text == '333');
    assert(ce1.getNode(3) is CodeBlockNode);
    assert(ce1.id == cell.id);

    var ce2 = cell.update(3, to(CodeBlockNode.from(['xxx', 'yyy'])));
    var ce2Last = ce2.last as CodeBlockNode;
    assert(ce2Last.codes[0] == 'xxx');
    assert(ce2Last.codes[1] == 'yyy');
    assert(ce2.getNode(0).text == '111');
    assert(ce2.getNode(1).text == '222');
    assert(ce2.getNode(2).text == '333');
    assert(ce2.id == cell.id);
  });

  test('replaceMore', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([RichTextSpan(text: '111')]),
      RichTextNode.from([RichTextSpan(text: '222')]),
      RichTextNode.from([RichTextSpan(text: '333')]),
      CodeBlockNode.from(['444', '555']),
    ]);
    var ce1 = cell.replaceMore(0, 3, []);
    var ce1n1 = ce1.first as CodeBlockNode;
    assert(ce1n1.codes[0] == '444');
    assert(ce1n1.codes[1] == '555');
    assert(ce1n1.id == cell.last.id);
    assert(ce1.id == cell.id);

    var ce2 = cell.replaceMore(1, 3, [
      CodeBlockNode.from(['222', '333'])
    ]);
    assert(ce2.length == 3);
    assert(ce2.id == cell.id);
    var ce2n1 = ce2.getNode(1) as CodeBlockNode;
    var ce2n2 = ce2.getNode(2) as CodeBlockNode;
    assert(ce2n1.codes[0] == '222');
    assert(ce2n1.codes[1] == '333');
    assert(ce2n2.codes[0] == '444');
    assert(ce2n2.codes[1] == '555');
  });

  test('moveTo', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([RichTextSpan(text: '111')]),
      RichTextNode.from([RichTextSpan(text: '222')]),
      RichTextNode.from([RichTextSpan(text: '333')]),
      CodeBlockNode.from(['444', '555']),
    ]);
    var ce1 = cell.moveTo(1, 4);
    assert(ce1.nodes[1].text == '333');
    assert(ce1.nodes.last.text == '222');
    assert(ce1.nodes[2] is CodeBlockNode);
  });

  test('insert', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([RichTextSpan(text: '111')]),
      RichTextNode.from([RichTextSpan(text: '222')]),
      RichTextNode.from([RichTextSpan(text: '333')]),
      CodeBlockNode.from(['444', '555']),
    ]);
    var ce1 = cell.insert(0, H1Node.from([RichTextSpan(text: '000')]));
    assert(ce1.nodes.first.text == '000');
    assert(ce1.nodes.first is H1Node);
    assert(ce1.nodes[1].text == '111');
  });

  test('getNodes', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([RichTextSpan(text: '111')]),
      RichTextNode.from([RichTextSpan(text: '222')]),
      RichTextNode.from([RichTextSpan(text: '333')]),
      CodeBlockNode.from(['444', '555']),
    ]);
    var list1 = cell.getNodes(EditingCursor(1, RichTextNodePosition.zero()),
        (EditingCursor(1, RichTextNodePosition(0, 2))));
    assert(list1.length == 1);
    assert(list1.first.text == '22');

    var list2 = cell.getNodes(EditingCursor(1, RichTextNodePosition.zero()),
        (EditingCursor(2, RichTextNodePosition(0, 2))));
    assert(list2.length == 2);
    assert(list2.first.text == '222');
    assert(list2.last.text == '33');

    var list3 = cell.getNodes(EditingCursor(1, RichTextNodePosition.zero()),
        (EditingCursor(3, CodeBlockPosition(1, 2))));
    assert(list3.length == 3);
    assert(list3.first.text == '222');
    assert(list3[1].text == '333');
    assert(list3[1].id == cell.getNode(2).id);
    assert(list3.last is CodeBlockNode);
    var l3n1 = list3.last as CodeBlockNode;
    assert(l3n1.codes.first == '444');
    assert(l3n1.codes.last == '55');
  });

  test('toJson', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([RichTextSpan(text: '111')]),
      RichTextNode.from([RichTextSpan(text: '222')]),
      RichTextNode.from([RichTextSpan(text: '333')]),
      CodeBlockNode.from(['444', '555']),
    ]);
    final json = cell.toJson();
    assert(json['type'] == '${cell.runtimeType}');
    final nodes = json['nodes'] as List<Map<String, dynamic>>;
    assert(nodes.length == cell.length);
    for (var i = 0; i < nodes.length; ++i) {
      var innerJson = nodes[i].toString();
      var node = cell.getNode(i);
      var nodeJson = node.toJson().toString();
      assert(innerJson == nodeJson);
    }
  });

  test('text', () {
    final cell = basicCell(nodes: [
      RichTextNode.from([RichTextSpan(text: '111')]),
      RichTextNode.from([RichTextSpan(text: '222')]),
      RichTextNode.from([RichTextSpan(text: '333')]),
      CodeBlockNode.from(['444', '555']),
    ]);
    final text = cell.text;
    assert(text == cell.nodes.map((e) => e.text).join('\n'));
  });
}
