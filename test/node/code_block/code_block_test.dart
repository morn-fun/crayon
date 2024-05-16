import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/code_block.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:crayon/editor/extension/string.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/code_block/code_block.dart';
import 'package:crayon/editor/node/code_block/generator/depth.dart';
import 'package:crayon/editor/node/code_block/generator/newline.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../config/const_texts.dart';
import '../../config/necessary.dart';
import '../../config/test_editor_node.dart';

void main() {
  CodeBlockNode basicNode({List<String>? texts}) =>
      CodeBlockNode.from(texts ?? constTexts);

  test('edge position', () {
    final node = basicNode();
    assert(node.beginPosition.offset == 0);
    assert(node.beginPosition.index == 0);
    assert(node.beginPosition.atEdge == true);
    assert(node.endPosition.offset == constTexts.last.length);
    assert(node.endPosition.index == constTexts.length - 1);
    assert(node.endPosition.atEdge == true);
  });

  test('frontPartNode', () {
    var node = basicNode();
    var n1 = node.frontPartNode(CodeBlockPosition(5, 0));
    assert(n1 is CodeBlockNode);
    final sublist = constTexts.sublist(0, 5).join();
    final text = n1.text.replaceAll('\n', '');
    assert(text == sublist);
  });

  test('rearPartNode', () {
    var node = basicNode();
    var n1 = node.rearPartNode(CodeBlockPosition(5, 0));
    assert(n1 is CodeBlockNode);
    final sublist = constTexts.sublist(5).join();
    final text = n1.text.replaceAll('\n', '');
    assert(text == sublist);
  });

  test('getFromPosition', () {
    var node = basicNode();
    var n1 = node.getFromPosition(node.beginPosition, node.endPosition);
    n1 = n1 as CodeBlockNode;
    assert(n1.text == node.text);
    assert(listEquals(n1.codes, node.codes));
    assert(n1.language == node.language);

    var n2 = node.getFromPosition(node.beginPosition, node.beginPosition);
    assert(n2 is RichTextNode);

    var n3 = node.getFromPosition(node.endPosition, node.endPosition);
    assert(n3 is RichTextNode);
    assert(n2.text == n3.text);

    var n4 = node.getFromPosition(CodeBlockPosition.zero(),
        CodeBlockPosition(0, node.codes.first.length));
    n4 = n4 as CodeBlockNode;
    assert(n4.codes.length == 1);
    assert(n4.codes.first == node.codes.first);

    var n5 = node.getFromPosition(
        CodeBlockPosition.zero(), CodeBlockPosition(2, node.codes[2].length));
    n5 = n5 as CodeBlockNode;
    assert(n5.codes.length == 3);
    int i = 0;
    for (var code in n5.codes) {
      assert(code == node.codes[i]);
      i++;
    }

    var n6 =
        node.getFromPosition(CodeBlockPosition(5, 5), CodeBlockPosition(3, 3));
    n6 = n6 as CodeBlockNode;
    assert(n6.codes.length == 3);
    assert(n6.codes.first == node.codes[3].substring(3));
    assert(n6.codes.last == node.codes[5].substring(0, 5));
    assert(n6.codes[1] == node.codes[4]);
  });

  test('isAllSelected', () {
    var node = basicNode();
    var isAllSelected = node.isAllSelected(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition));
    assert(isAllSelected);

    isAllSelected = node.isAllSelected(
        SelectingNodeCursor(0, node.beginPosition, CodeBlockPosition(0, 5)));
    assert(!isAllSelected);

    isAllSelected = node.isAllSelected(
        SelectingNodeCursor(0, CodeBlockPosition(0, 5), node.endPosition));
    assert(!isAllSelected);

    isAllSelected = node.isAllSelected(SelectingNodeCursor(
        0, CodeBlockPosition(2, 5), CodeBlockPosition(5, 2)));
    assert(!isAllSelected);
  });

  test('replace', () {
    var node = basicNode();
    final text = '111', text2 = '222';
    var n1 = node.replace(node.beginPosition, node.endPosition, []);
    assert(n1.codes.length == 1);
    assert(n1.codes.first.isEmpty);

    var n2 = node.replace(CodeBlockPosition(2, 0), CodeBlockPosition(5, 0), []);
    assert(n2.codes[2] == node.codes[5]);
    assert(n2.codes[3] == node.codes[6]);

    var n3 =
        node.replace(CodeBlockPosition(2, 0), CodeBlockPosition(5, 0), [text]);
    assert(n3.codes[2] == text + node.codes[5]);
    assert(n3.codes[3] == node.codes[6]);

    var n4 = node.replace(CodeBlockPosition(2, 5), CodeBlockPosition(5, 2), []);
    assert(n4.codes[2] ==
        node.codes[2].substring(0, 5) + node.codes[5].substring(2));
    assert(n4.codes[3] == node.codes[6]);

    var n5 =
        node.replace(CodeBlockPosition(2, 5), CodeBlockPosition(5, 2), [text]);
    assert(n5.codes[2] ==
        node.codes[2].substring(0, 5) + text + node.codes[5].substring(2));
    assert(n5.codes[3] == node.codes[6]);

    var n6 = node.replace(
        CodeBlockPosition(2, 5), CodeBlockPosition(5, 2), [text, text2]);
    assert(n6.codes[2] == node.codes[2].substring(0, 5) + text);
    assert(n6.codes[3] == text2 + node.codes[5].substring(2));
    assert(n6.codes[4] == node.codes[6]);
  });

  test('merge', () {
    var node = basicNode();
    final text = '111', text2 = '222';
    var n1 = node.merge(RichTextNode.from([RichTextSpan(text: text)]));
    assert(n1.codes.length == node.codes.length + 1);
    assert(n1.codes.last == text);

    expect(() => node.merge(TestEditorNode()),
        throwsA(const TypeMatcher<UnableToMergeException>()));

    var n2 = node.merge(node, newId: text2);
    assert(n2.id == text2);
    assert(n2.codes.length == node.codes.length * 2 - 1);
    assert(
        n2.codes[node.codes.length - 1] == node.codes.last + node.codes.first);
  });

  test('newNode', () {
    var node = basicNode();
    var n1 = node.newNode();
    assert(n1.id == node.id);
    assert(n1.depth == node.depth);
    assert(listEquals(n1.codes, node.codes));

    var n2 = node.newNode(id: '1');
    assert(n2.id == '1');
    assert(n2.id != node.id);
    assert(n2.depth == node.depth);
    assert(listEquals(n2.codes, node.codes));

    var n3 = node.newNode(id: '2', depth: 2);
    assert(n3.id == '2');
    assert(n3.id != node.id);
    assert(n3.depth != node.depth);
    assert(n3.depth != 3);
    assert(listEquals(n3.codes, node.codes));
  });

  test('newLanguage', () {
    var node = basicNode();
    assert(node.language == 'dart');
    var n1 = node.newLanguage('rust');
    assert(n1.language == 'rust');
  });

  test('lastPosition', () {
    var node = CodeBlockNode.from(['', '', '111', '222']);

    expect(() => node.lastPosition(node.beginPosition),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));

    var p1 = node.lastPosition(CodeBlockPosition(1, 0));
    assert(p1 == CodeBlockPosition(0, 0));

    var p2 = node.lastPosition(CodeBlockPosition(2, 0));
    assert(p2 == CodeBlockPosition(1, 0));

    var p3 = node.lastPosition(CodeBlockPosition(3, 0));
    assert(p3 == CodeBlockPosition(2, 3));

    var p4 = node.lastPosition(CodeBlockPosition(2, 1));
    assert(p4 == CodeBlockPosition(2, 0));

    expect(() => node.lastPosition(CodeBlockPosition(0, 1)),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));

    expect(() => node.lastPosition(CodeBlockPosition(1, 1)),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));
  });

  test('nextPosition', () {
    var node = CodeBlockNode.from(['', '', '111', '222']);
    expect(() => node.nextPosition(node.endPosition),
        throwsA(const TypeMatcher<ArrowRightEndException>()));

    var p1 = node.nextPosition(CodeBlockPosition(1, 0));
    assert(p1 == CodeBlockPosition(2, 0));

    var p2 = node.nextPosition(CodeBlockPosition(2, 0));
    assert(p2 == CodeBlockPosition(2, 1));

    expect(() => node.nextPosition(CodeBlockPosition(0, 1)),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
  });

  test('toJson', () {
    var node = basicNode();
    final json = node.toJson();
    assert(json['type'] == '${node.runtimeType}');
    assert(json['codes'] == node.codes);
  });

  test('getInlineNodesFromPosition', () {
    var node = basicNode();
    assert(node
        .getInlineNodesFromPosition(node.beginPosition, node.endPosition)
        .isEmpty);
  });

  test('onEdit-delete', () {
    var node = basicNode();
    final ctx = buildTextContext([node]);
    expect(
        () => node.onEdit(
            EditingData(node.beginPosition.toCursor(0), EventType.italic, ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
    var r1 = node.onEdit(
        EditingData(node.beginPosition.toCursor(0), EventType.delete, ctx));
    var n1 = r1.node as CodeBlockNode;
    var c1 = r1.cursor as SelectingNodeCursor;
    assert(n1.hashCode == node.hashCode);
    assert(c1.index == 0);
    assert(c1 == SelectingNodeCursor(0, node.beginPosition, node.endPosition));

    var r2 = node.onEdit(EditingData(
        CodeBlockPosition(1, 0).toCursor(0), EventType.delete, ctx));
    var n2 = r2.node as CodeBlockNode;
    var c2 = r2.cursor as EditingCursor;
    assert(n2.codes.length == node.codes.length - 1);
    assert(n2.codes.first == node.codes.first + node.codes[1]);
    assert(c2.index == 0);
    assert(c2.position == CodeBlockPosition(0, n1.codes.first.length));

    var r3 = node.onEdit(EditingData(
        CodeBlockPosition(3, 3).toCursor(0), EventType.delete, ctx));
    var n3 = r3.node as CodeBlockNode;
    var c3 = r3.cursor as EditingCursor;
    assert(n3.codes[3] == node.codes[3].removeAt(3).text);
    assert(c3.index == 0);
    assert(c3.position == CodeBlockPosition(3, 2));
  });

  test('onEdit-delete', () {
    var node = basicNode();
    final ctx = buildTextContext([node]);
    var r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition),
        EventType.delete,
        ctx));
    var n1 = r1.node as RichTextNode;
    var c1 = r1.cursor as EditingCursor;
    assert(n1.text.isEmpty);
    assert(c1.position == n1.beginPosition);

    var r2 = node.onSelect(SelectingData(
        SelectingNodeCursor(
            0, CodeBlockPosition(1, 2), CodeBlockPosition(5, 1)),
        EventType.delete,
        ctx));
    var n2 = r2.node as CodeBlockNode;
    var c2 = r2.cursor as EditingCursor;
    assert(listEquals(
        n2.codes,
        node.replace(
            CodeBlockPosition(1, 2), CodeBlockPosition(5, 1), []).codes));
    assert(c2.position == CodeBlockPosition(1, 2));
  });

  test('onEdit-newline', () {
    var node = basicNode(texts: ['   1', '  2', ' 3']);
    final ctx = buildTextContext([node]);
    var r1 = node.onEdit(EditingData(
        CodeBlockPosition(1, 0).toCursor(0), EventType.newline, ctx));
    var n1 = r1.node as CodeBlockNode;
    var c1 = r1.cursor as EditingCursor;
    assert(n1.codes.length == node.codes.length + 1);
    assert(n1.codes[1].isEmpty);
    assert(c1.index == 0);
    assert(c1.position == CodeBlockPosition(2, 0));

    var r2 = node.onEdit(EditingData(
        CodeBlockPosition(0, node.codes.first.length).toCursor(0),
        EventType.newline,
        ctx));
    var n2 = r2.node as CodeBlockNode;
    var c2 = r2.cursor as EditingCursor;
    assert(n2.codes.length == node.codes.length + 1);
    assert(n2.codes[1] == getTab(node.codes.first));
    assert(c2.index == 0);
    assert(
        c2.position == CodeBlockPosition(1, getTab(node.codes.first).length));
  });

  test('onSelect-newline', () {
    var node = basicNode();
    final ctx = buildTextContext([node]);
    var r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition),
        EventType.newline,
        ctx));
    var n1 = r1.node as CodeBlockNode;
    var c1 = r1.cursor as EditingCursor;
    assert(n1.codes.length == 2);
    assert(c1.position == CodeBlockPosition(1, 0));
  });

  test('onEdit-selectAll', () {
    var node = basicNode(texts: ['', '1', '2']);
    final ctx = buildTextContext([node]);
    var r1 = node.onEdit(
        EditingData(node.beginPosition.toCursor(0), EventType.selectAll, ctx));
    var c1 = r1.cursor as SelectingNodeCursor;
    assert(c1.begin == node.beginPosition.copy(atEdge: false));
    assert(c1.end == node.endPosition.copy(atEdge: false));

    var r2 = node.onEdit(EditingData(
        CodeBlockPosition(1, 0).toCursor(0), EventType.selectAll, ctx));
    var c2 = r2.cursor as SelectingNodeCursor;
    assert(c2.begin == CodeBlockPosition(1, 0));
    assert(c2.end == CodeBlockPosition(1, node.codes[1].length));
  });

  test('onSelect-selectAll', () {
    var node = basicNode();
    final ctx = buildTextContext([node]);
    var r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(
            0, CodeBlockPosition(0, 0), CodeBlockPosition(0, 1)),
        EventType.selectAll,
        ctx));
    var n1 = r1.node as CodeBlockNode;
    var c1 = r1.cursor as SelectingNodeCursor;
    assert(n1.hashCode == node.hashCode);
    assert(c1.begin == node.beginPosition.copy(atEdge: false));
    assert(c1.end == node.endPosition.copy(atEdge: false));

    var r2 = node.onSelect(SelectingData(c1, EventType.selectAll, ctx));
    var c2 = r2.cursor as SelectingNodeCursor;
    assert(c2.begin == node.beginPosition);
    assert(c2.end == node.endPosition);
  });

  test('onEdit-increaseDepth', () {
    var node = basicNode();
    final ctx = buildTextContext([node]);
    var r1 = node.onEdit(EditingData(
        CodeBlockPosition.zero().toCursor(0), EventType.increaseDepth, ctx));
    var n1 = r1.node as CodeBlockNode;
    var c1 = r1.cursor as EditingCursor;
    assert(n1.codes.first == tab + node.codes.first);
    assert(c1.position == CodeBlockPosition(0, tab.length));
  });

  test('onEdit-decreaseDepth', () {
    var node = basicNode(texts: ['', '  ', '   ']);
    final ctx = buildTextContext([node]);

    expect(
        () => node.onEdit(EditingData(CodeBlockPosition.zero().toCursor(0),
            EventType.decreaseDepth, ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));

    var r1 = node.onEdit(EditingData(
        CodeBlockPosition(1, 0).toCursor(0), EventType.decreaseDepth, ctx));
    var n1 = r1.node as CodeBlockNode;
    var c1 = r1.cursor as EditingCursor;
    assert(n1.codes[0].isEmpty);
    assert(c1.position == CodeBlockPosition(1, 0));
  });

  test('onSelect-increaseDepth', () {
    var node = basicNode();
    final ctx = buildTextContext([node]);

    expect(
        () => node.newNode(depth: 100).onSelect(SelectingData(
            SelectingNodeCursor(0, node.beginPosition, node.endPosition),
            EventType.increaseDepth,
            ctx,
            extras: 1)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));

    var r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(
            0, CodeBlockPosition.zero(), CodeBlockPosition(0, 1)),
        EventType.increaseDepth,
        ctx));
    var n1 = r1.node as CodeBlockNode;
    var c1 = r1.cursor as SelectingNodeCursor;
    assert(n1.codes.first == tab + node.codes.first);
    assert(n1.codes[1] == node.codes[1]);
    assert(c1.begin == CodeBlockPosition(0, tab.length));
    assert(c1.end == CodeBlockPosition(0, tab.length + 1));

    var r2 = node.onSelect(SelectingData(
        SelectingNodeCursor(
            0, CodeBlockPosition.zero(), CodeBlockPosition(3, 2)),
        EventType.increaseDepth,
        ctx));
    var n2 = r2.node as CodeBlockNode;
    var c2 = r2.cursor as SelectingNodeCursor;
    assert(c2.begin == CodeBlockPosition(0, tab.length));
    assert(c2.end == CodeBlockPosition(3, tab.length + 2));
    for (var i = 0; i < 4; ++i) {
      var code = n2.codes[i];
      var oldCode = node.codes[i];
      assert(code == tab + oldCode);
    }

    var r3 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition),
        EventType.increaseDepth,
        ctx,
        extras: 1));
    var n3 = r3.node as CodeBlockNode;
    var c3 = r3.cursor as SelectingNodeCursor;
    assert(n3.depth == node.depth + 1);
    assert(listEquals(n3.codes, node.codes));
    assert(c3.begin == node.beginPosition);
    assert(c3.end == node.endPosition);
  });

  test('onSelect-decreaseDepth', () {
    var node = basicNode();
    var ctx = buildTextContext([node]);

    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(0, node.beginPosition, node.endPosition),
            EventType.decreaseDepth,
            ctx)),
        throwsA(const TypeMatcher<DepthNeedDecreaseMoreException>()));

    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(
                0, CodeBlockPosition(0, 1), CodeBlockPosition(4, 3)),
            EventType.decreaseDepth,
            ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));

    node = basicNode(texts: ['', '  11', '   222', '    3333']);
    ctx = buildTextContext([node]);

    var r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(
            0, CodeBlockPosition.zero(), CodeBlockPosition(2, 4)),
        EventType.decreaseDepth,
        ctx));
    var n1 = r1.node as CodeBlockNode;
    var c1 = r1.cursor as SelectingNodeCursor;
    assert(listEquals(n1.codes, ['', '11', '222', '    3333']));
    assert(c1.begin == CodeBlockPosition.zero());
    assert(c1.end == CodeBlockPosition(2, 1));
  });

  test('onSelect', () {});
}