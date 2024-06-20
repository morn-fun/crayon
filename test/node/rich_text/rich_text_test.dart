import 'dart:math';
import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/exception/menu.dart';
import 'package:crayon/editor/node/rich_text/generator/typing.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/shortcuts/styles.dart';
import 'package:flutter/cupertino.dart' hide RichText;
import 'package:flutter_test/flutter_test.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:crayon/editor/node/basic.dart';

import '../../config/const_texts.dart';
import '../../config/necessary.dart';
import '../../config/test_editor_node.dart';

typedef SpanGenerator = RichTextSpan Function(String text, int offset);

RichTextNode basicTextNode({
  List<String>? texts,
  SpanGenerator? generator,
  bool mergeSpan = false,
}) {
  final spans = <RichTextSpan>[];
  for (var text in (texts ?? constTexts)) {
    final isFirst = spans.isEmpty;
    final offset = isFirst ? 0 : spans.last.endOffset;
    spans.add(generator?.call(text, offset) ??
        RichTextSpan(text: text, offset: offset));
  }

  return RichTextNode.from(mergeSpan ? RichTextSpan.mergeList(spans) : spans);
}

void main() {
  test('frontPartNode', () {
    final newNode = basicTextNode();
    final node1 = newNode.frontPartNode(RichTextNodePosition(4, 5));
    assert(node1.spans.length == 1);
    final realText =
        constTexts.sublist(0, 4).join() + constTexts[4].substring(0, 5);
    assert(node1.text == realText);
    assert(node1.spans.first.offset == newNode.spans.first.offset);
    assert(node1.spans.first.endOffset ==
        node1.spans.first.offset + realText.length);
  });

  test('rearPartNode', () {
    int i = 0;
    final newNode = basicTextNode(
        generator: (text, offset) =>
            RichTextSpan(text: text, offset: offset, tags: {'${i++}'}));
    final node1 = newNode.rearPartNode(RichTextNodePosition(4, 5));
    assert(node1.getSpan(0).text == constTexts[4].substring(5));
    assert(node1.getSpan(0).text != constTexts[4]);
    assert(node1.getSpan(1).text == constTexts[5]);
    assert(node1.getSpan(2).text == constTexts[6]);
    assert(node1.getSpan(3).text == constTexts[7]);
    assert(node1.getSpan(4).text == constTexts[8]);
    assert(node1.getSpan(5).text == constTexts[9]);
    for (var i = 1; i < node1.spans.length; ++i) {
      var currentSpan = node1.getSpan(i);
      assert(currentSpan.offset == node1.getSpan(i - 1).endOffset);
    }

    assert(newNode.rearPartNode(newNode.endPosition).spans.length == 1);

    final node2 =
        node1.rearPartNode(RichTextNodePosition(node1.spans.length - 1, 0));
    assert(node2.spans.length == 1);
    assert(node2.spans.last.text == node1.spans.last.text);

    final node3 = node1.rearPartNode(RichTextNodePosition(
        node1.spans.length - 2,
        node1.getSpan(node1.spans.length - 2).textLength));
    assert(node3.spans.length == 1);
  });

  test('locateSpanIndex', () {
    final newNode = basicTextNode();
    int i = 0;
    for (var span in newNode.spans) {
      final startOff = span.offset;
      final startOffIndex = newNode.locateSpanIndex(startOff);
      final startOffIndex1 = newNode.locateSpanIndex(startOff - 1);
      final startOffIndex2 = newNode.locateSpanIndex(startOff + 1);

      assert(startOffIndex == i || startOffIndex == i - 1);
      assert(startOffIndex1 == i || startOffIndex1 == i - 1);
      assert(startOffIndex2 == i);

      final endOff = span.endOffset;
      final endOffIndex = newNode.locateSpanIndex(endOff);
      final endOffIndex1 = newNode.locateSpanIndex(endOff - 1);
      final endOffIndex2 = newNode.locateSpanIndex(endOff + 1);

      assert(endOffIndex == i || endOffIndex == i + 1);
      assert(endOffIndex1 == i);
      assert(endOffIndex2 == i || endOffIndex2 == i + 1);
      i++;
    }
  });

  test('insert', () {
    final newNode = basicTextNode();
    final node1 = newNode.insert(0, RichTextSpan(text: 'a' * 5));
    assert(node1.spans.length == 1);
    int offset = 0;
    for (var span in node1.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node2 = newNode.insert(5, RichTextSpan(text: 'a' * 5));
    assert(node2.spans.length == 1);

    offset = 0;
    for (var span in node2.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }
  });

  test('merge', () {
    final newNode = basicTextNode();
    final node1 = newNode.merge(basicTextNode());
    assert(node1.spans.length == 1);
    int offset = 0;
    for (var span in node1.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node2 = node1.merge(newNode);
    assert(node2.spans.length == 1);
    offset = 0;
    for (var span in node1.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    expect(() => newNode.merge(TestEditorNode()),
        throwsA(const TypeMatcher<UnableToMergeException>()));
  });

  test('update', () {
    int i = 0;
    final newNode = basicTextNode(
        generator: (text, offset) =>
            RichTextSpan(text: text, offset: offset, tags: {'${i++}'}));
    final node1 = newNode.update(0, RichTextSpan(text: 'a' * 5));
    assert(node1.spans.length == constTexts.length);
    assert(node1.spans.first.textLength == 5);
    var offset = 0;
    for (var span in node1.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node2 = newNode.update(5, RichTextSpan(text: 'a' * 5));
    assert(node2.spans.length == constTexts.length);
    assert(node2.spans[5].textLength == 5);
    offset = 0;
    for (var span in node2.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node3 =
        newNode.update(newNode.spans.length - 1, RichTextSpan(text: 'a' * 5));
    assert(node3.spans.length == constTexts.length);
    assert(node3.spans.last.textLength == 5);
    offset = 0;
    for (var span in node3.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }
  });

  test('replace', () {
    final newNode = basicTextNode();
    const newId = '111';
    final node1 = newNode
        .replace(newNode.beginPosition, newNode.endPosition, [], newId: newId);
    assert(node1.id == newId);
    assert(newNode.id != newId);
    var offset = 0;
    for (var span in node1.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node2 = node1.replace(RichTextNodePosition.zero(),
        RichTextNodePosition.zero(), [RichTextSpan(text: 'abc')]);
    assert(node2.spans.length == 1);
    offset = 0;
    for (var span in node2.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node3 = newNode
        .replace(RichTextNodePosition(3, 0), RichTextNodePosition(5, 0), []);
    assert(node3.spans.length == 1);
    offset = 0;
    for (var span in node3.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node4 = newNode.replace(RichTextNodePosition(3, 0),
        RichTextNodePosition(5, 0), [RichTextSpan(text: 'x')]);
    assert(node4.spans.length == 1);
    offset = 0;
    for (var span in node4.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node5 = newNode
        .replace(RichTextNodePosition(3, 5), RichTextNodePosition(7, 9), [
      RichTextSpan(text: 'abc', tags: {'a'}),
      RichTextSpan(text: '123', tags: {'b'}),
      RichTextSpan(text: 'xyz'),
    ]);
    assert(node5.spans.length == 4);
    offset = 0;
    for (var span in node5.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node6 = newNode
        .replace(RichTextNodePosition(2, 1), RichTextNodePosition(2, 13), [
      RichTextSpan(text: 'abc'),
      RichTextSpan(text: '123'),
      RichTextSpan(text: 'xyz'),
    ]);
    assert(node6.spans.length == 1);
    offset = 0;
    for (var span in node6.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node7 = RichTextNode.from([])
        .replace(RichTextNodePosition.zero(), RichTextNodePosition.zero(), []);
    assert(node7.spans.length == 1);
  });

  test('delete', () {
    int i = 0;
    final newNode = basicTextNode(
        texts: ['abc', 'xyz', 'l'],
        generator: (text, offset) =>
            RichTextSpan(text: text, offset: offset, tags: {'${i++}'}));
    final np1 = newNode.delete(
        RichTextNodePosition(0, newNode.spans.first.textLength), 0);
    assert((np1.cursor as EditingCursor).position is RichTextNodePosition);
    assert(((np1.cursor as EditingCursor).position as RichTextNodePosition)
            .offset ==
        newNode.spans.first.textLength - 1);
    final node1 = np1.node as RichTextNode;
    assert(node1.spans.first.text == 'ab');
    expect(() => newNode.delete(RichTextNodePosition(0, 0), 0),
        throwsA(const TypeMatcher<DeleteRequiresNewLineException>()));

    final np2 = newNode.delete(RichTextNodePosition(0, 1), 0);
    final node2 = np2.node as RichTextNode;
    assert(node2.spans.first.text == 'bc');
    assert(np2.cursor is EditingCursor);

    final np3 = newNode.delete(RichTextNodePosition(1, 0), 0);
    assert(np3.cursor is EditingCursor);
    final node3 = np3.node as RichTextNode;
    assert(node3.spans.first.text == 'ab');

    final np4 = newNode.delete(RichTextNodePosition(2, 1), 0);
    assert(np4.cursor is EditingCursor);
    assert(((np4.cursor as EditingCursor).position as RichTextNodePosition)
            .offset ==
        newNode.spans[1].textLength);
    final node4 = np4.node as RichTextNode;
    assert(node4.spans.length == 2);
  });

  test('buildTextSpan', () {
    final newNode = basicTextNode(texts: ['aaaaaa', 'bbbbbb', 'cccccc']);
    final span1 = newNode.buildTextSpan();
    assert(span1.children != null);
    assert(span1.children!.length == newNode.spans.length);

    final styleNode = basicTextNode(
        generator: (text, offset) => RichTextSpan(
                text: text,
                offset: offset,
                tags: {
                  RichTextTag
                      .values[Random().nextInt(RichTextTag.values.length)].name
                }));
    final span2 = styleNode.buildTextSpan();
    for (var i = 0; i < styleNode.spans.length; ++i) {
      var richTextSpan = styleNode.spans[i];
      var inlineSpan = span2.children![i] as TextSpan;
      var style = inlineSpan.style!;
      final tag = richTextSpan.tags.first;
      if (tag != RichTextTag.link.name) {
        var mergeStyle = style.merge(tag2Style[tag]);
        assert(style == mergeStyle);
      }
    }
  });

  test('merge', () {
    final node1 = basicTextNode(texts: ['aaa', 'bbb']);
    final node2 = basicTextNode(texts: ['ccc', 'ddd']);
    final node3 = basicTextNode(
        texts: ['mmm', 'nnn'],
        generator: (text, offset) => RichTextSpan(
            text: text, offset: offset, tags: {RichTextTag.bold.name}));
    final node4 = basicTextNode(
        texts: ['xxx', 'yyy'],
        generator: (text, offset) => RichTextSpan(
            text: text, offset: offset, tags: {RichTextTag.bold.name}));
    final node5 = basicTextNode(
        texts: ['zzz', 'ZZZ'],
        generator: (text, offset) => RichTextSpan(
            text: text, offset: offset, tags: {RichTextTag.italic.name}));
    final mergeNode1 = node1.merge(node2);
    assert(mergeNode1.text == node1.text + node2.text);
    assert(mergeNode1.spans.length == 1);

    final mergeNode2 = node2.merge(node3);
    assert(mergeNode2.text == node2.text + node3.text);
    assert(mergeNode2.spans.length == 2);

    final mergeNode3 = node3.merge(node4);
    assert(mergeNode3.text == node3.text + node4.text);
    assert(mergeNode3.spans.length == 1);

    final mergeNode4 = node4.merge(node5);
    assert(mergeNode4.text == node4.text + node5.text);
    assert(mergeNode4.spans.length == 2);

    final mergeNode6 = node1.merge(node3).merge(node5);
    assert(mergeNode6.text == node1.text + node3.text + node5.text);
    assert(mergeNode6.spans.length == 3);
  });

  test('toJson', () {
    final newNode = basicTextNode(texts: ['aaa', 'bbb']);
    final json = newNode.toJson();
    final spans = json['spans'] as List<Map<String, dynamic>>;
    for (var n in spans) {
      assert(n.keys.contains('attributes'));
      assert(n.keys.contains('text'));
      assert(!n.keys.contains('tags'));
    }
  });

  testWidgets('build', (tester) async {
    final node = basicTextNode(texts: ['aaa', 'bbb']);
    final ctx = buildEditorContext([node]);
    var widget =
        Builder(builder: (c) => node.build(ctx, NodeBuildParam.empty(), c));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ));
  });

  test('insertByPosition', () {
    final newNode = basicTextNode(texts: ['aaa', 'bbb']);
    final node1 = newNode.insertByPosition(
        RichTextNodePosition(0, 1), RichTextSpan(text: 'AA'));
    assert(node1.text == 'aAAaabbb');
    assert(node1.spans.length == 1);

    final node2 = newNode.insertByPosition(
        RichTextNodePosition(0, 1), RichTextSpan(text: 'AA', tags: {'a'}));
    assert(node2.text == 'aAAaabbb');
    assert(node2.spans.length == 3);

    final node3 = newNode.insertByPosition(
        RichTextNodePosition(0, 1), RichTextSpan(text: '', tags: {'a'}));
    assert(node3.text == 'aaabbb');
    assert(node3.spans.length == 1);

    final node4 = newNode.insertByPosition(
        RichTextNodePosition(0, 1), RichTextSpan(text: '', tags: {'a'}));
    assert(node4.text == 'aaabbb');
    assert(node4.spans.length == 1);

    final node5 = newNode.insertByPosition(
        RichTextNodePosition(0, 1), RichTextSpan(text: 'AA', tags: {'a'}));
    assert(node5.text == 'aAAaabbb');
    assert(node5.spans.length == 3);
  });

  test('remove', () {
    final newNode = basicTextNode();
    final node1 =
        newNode.remove(RichTextNodePosition(0, 0), RichTextNodePosition(1, 0));
    assert(node1.spans.length == 1);
    assert(node1.text == constTexts.join().replaceFirst(constTexts[0], ''));

    final node2 =
        newNode.remove(RichTextNodePosition(1, 0), RichTextNodePosition(0, 0));
    assert(node2.text == node1.text);

    final node3 = newNode.remove(RichTextNodePosition(0, 0),
        RichTextNodePosition(constTexts.length - 1, 0));
    assert(node3.text == constTexts.last);

    final node4 = newNode.remove(RichTextNodePosition(0, 0),
        RichTextNodePosition(constTexts.length - 1, constTexts.last.length));
    assert(node4.text.isEmpty);

    final node5 =
        newNode.remove(RichTextNodePosition(3, 0), RichTextNodePosition(5, 0));
    final guessText =
        constTexts.sublist(0, 3).join() + constTexts.skip(5).join();
    assert(node5.text == guessText);
  });

  test('getPositionByOffset', () {
    int i = 0;
    final newNode = basicTextNode(
        generator: (text, offset) =>
            RichTextSpan(text: text, offset: offset, tags: {'${i++}'}));
    i = 0;
    int offset = 0;
    for (var text in constTexts) {
      final p1 = newNode.getPositionByOffset(offset);
      offset += text.length;
      assert(p1.index == i ||
          (p1.index == i - 1 && p1.offset == constTexts[i - 1].length));
      i++;
    }
  });

  test('buildSpansByAddingTag', () {
    final newNode = basicTextNode();
    for (var span in newNode.spans) {
      assert(span.tags.isEmpty);
    }

    final spanList1 = newNode.buildSpansByAddingTag('tag');
    for (var span in spanList1) {
      assert(span.tags.length == 1);
      assert(span.tags.contains('tag'));
    }
  });

  test('buildSpansByAddingTag', () {
    final newNode = basicTextNode(
        generator: (text, offset) =>
            RichTextSpan(text: text, offset: offset, tags: {'tag'}));

    for (var span in newNode.spans) {
      assert(span.tags.length == 1);
      assert(span.tags.first == 'tag');
    }

    final spanList1 = newNode.buildSpansByRemovingTag('tag');
    for (var span in spanList1) {
      assert(span.tags.isEmpty);
    }

    final spanList2 = newNode.buildSpansByRemovingTag('xxx');
    for (var span in spanList2) {
      assert(span.tags.isNotEmpty);
    }
  });

  test('lastPosition', () {
    final newNode = basicTextNode(texts: ['', '', 'aaa', 'bbb']);
    expect(() => newNode.lastPosition(RichTextNodePosition(0, 0)),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));
    expect(() => newNode.lastPosition(RichTextNodePosition(0, 1)),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));
    expect(() => newNode.lastPosition(RichTextNodePosition(1, 0)),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));
    expect(() => newNode.lastPosition(RichTextNodePosition(2, 0)),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));

    final p1 = newNode.lastPosition(RichTextNodePosition(2, 1));
    assert(p1 == RichTextNodePosition(2, 0));

    final p2 = newNode.lastPosition(RichTextNodePosition(2, 2));
    assert(p2 == RichTextNodePosition(2, 1));

    final p3 = newNode.lastPosition(RichTextNodePosition(3, 0));
    assert(p3 == RichTextNodePosition(2, 2));

    final p4 = newNode.lastPosition(RichTextNodePosition(3, 3));
    assert(p4 == RichTextNodePosition(3, 2));
  });

  test('nextPositionByLength', () {
    final newNode = basicTextNode(texts: ['aaa', 'bbb', '', '']);
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(1, 3), 1),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(2, 0), 1),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(0, 0), 6),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(0, 3), 3),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(1, 0), 3),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(1, 1), 2),
        throwsA(const TypeMatcher<ArrowRightEndException>()));

    final p1 = newNode.nextPosition(RichTextNodePosition(0, 0));
    assert(p1 == RichTextNodePosition(0, 1));

    final p2 = newNode.nextPosition(RichTextNodePosition(0, 3));
    assert(p2 == RichTextNodePosition(1, 1));

    final p3 = newNode.nextPosition(RichTextNodePosition(1, 1));
    assert(p3 == RichTextNodePosition(1, 2));
  });

  test('nextPosition', () {
    final newNode = basicTextNode(texts: ['aaa', 'bbb', '', '']);
    expect(() => newNode.nextPosition(RichTextNodePosition(1, 3)),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPosition(RichTextNodePosition(2, 0)),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPosition(RichTextNodePosition(3, 0)),
        throwsA(const TypeMatcher<ArrowRightEndException>()));

    final p1 = newNode.nextPosition(RichTextNodePosition(0, 0));
    assert(p1 == RichTextNodePosition(0, 1));

    final p2 = newNode.nextPosition(RichTextNodePosition(0, 3));
    assert(p2 == RichTextNodePosition(1, 1));

    final p3 = newNode.nextPosition(RichTextNodePosition(1, 1));
    assert(p3 == RichTextNodePosition(1, 2));
  });

  test('getInlineNodesFromPosition', () {
    final node = basicTextNode();
    var n1 =
        node.getInlineNodesFromPosition(node.beginPosition, node.endPosition);
    assert(n1.length == 1);
    assert(n1.first.text == node.text);
  });

  test('newIdNode', () {
    final newNode = basicTextNode();
    final node1 = newNode.newNode(id: 'aaa') as RichTextNode;
    assert(node1.id == 'aaa');
    assert(newNode.id != node1.id);
    assert(newNode.text == node1.text);
    assert(newNode.spans.length == node1.spans.length);
  });

  test('onSelect-deletion', () {
    final node = basicTextNode();
    final ctx = buildEditorContext([node]);
    var r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition),
        EventType.delete,
        ctx));
    var n1 = r1.node as RichTextNode;
    var c1 = r1.cursor as EditingCursor;
    assert(n1.text.isEmpty);
    assert(c1.index == 0);
    assert(c1.position == RichTextNodePosition.zero());
  });

  test('onEdit', () {
    final node = basicTextNode();
    final ctx = buildEditorContext([node]);
    expect(
        () => node.onEdit(EditingData(
            EditingCursor(0, node.beginPosition), EventType.italic, ctx,
            extras: 0)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
  });

  test('onEdit-increaseDepth', () {
    final node = basicTextNode();
    final ctx = buildEditorContext([node]);
    var r1 = node.onEdit(EditingData(
        EditingCursor(0, node.beginPosition), EventType.increaseDepth, ctx));
    var n1 = r1.node as RichTextNode;
    var c1 = r1.cursor as EditingCursor;
    assert(c1.position == node.beginPosition);
    assert(n1.depth == node.depth + 1);
    var newNode = node.newNode(depth: 10);
    expect(
        () => newNode.onEdit(EditingData(
            EditingCursor(0, newNode.beginPosition),
            EventType.increaseDepth,
            ctx,
            extras: 0)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
  });

  test('onSelect-increaseDepth', () {
    final node = basicTextNode();
    final ctx = buildEditorContext([node]);
    var r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition),
        EventType.increaseDepth,
        ctx));
    var n1 = r1.node as RichTextNode;
    var c1 = r1.cursor as SelectingNodeCursor;
    assert(c1.begin == node.beginPosition);
    assert(c1.end == node.endPosition);
    assert(n1.depth == node.depth + 1);
    var newNode = node.newNode(depth: 10);
    expect(
        () => newNode.onSelect(SelectingData(
            SelectingNodeCursor(0, newNode.beginPosition, newNode.endPosition),
            EventType.increaseDepth,
            ctx,
            extras: 0)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
  });

  test('onEdit-decreaseDepth', () {
    final node = basicTextNode();
    final ctx = buildEditorContext([node]);
    expect(
        () => node.onEdit(EditingData(
            EditingCursor(0, node.beginPosition), EventType.decreaseDepth, ctx,
            extras: 0)),
        throwsA(const TypeMatcher<DepthNeedDecreaseMoreException>()));
  });

  test('onSelect-decreaseDepth', () {
    final node = basicTextNode();
    final ctx = buildEditorContext([node]);
    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(0, node.beginPosition, node.endPosition),
            EventType.decreaseDepth,
            ctx,
            extras: 0)),
        throwsA(const TypeMatcher<DepthNeedDecreaseMoreException>()));
  });

  test('onEdit-selectAll', () {
    final node = basicTextNode();
    final ctx = buildEditorContext([node]);
    var r1 = node.onEdit(EditingData(
        EditingCursor(0, node.beginPosition), EventType.selectAll, ctx));
    var n1 = r1.node as RichTextNode;
    var c1 = r1.cursor as SelectingNodeCursor;
    assert(c1.begin == n1.beginPosition);
    assert(c1.end == n1.endPosition);

    var newNode = basicTextNode(texts: ['']);
    expect(
        () => newNode.onEdit(EditingData(
            EditingCursor(0, newNode.beginPosition), EventType.selectAll, ctx)),
        throwsA(const TypeMatcher<EmptyNodeToSelectAllException>()));
  });

  test('onSelect-selectAll', () {
    final node = basicTextNode();
    final ctx = buildEditorContext([node]);
    var r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(
            0, RichTextNodePosition(5, 0), RichTextNodePosition(7, 0)),
        EventType.selectAll,
        ctx));
    var n1 = r1.node as RichTextNode;
    var c1 = r1.cursor as SelectingNodeCursor;
    assert(c1.begin == n1.beginPosition);
    assert(c1.end == n1.endPosition);
  });

  test('onSelect-styles', () {
    final node = basicTextNode(texts: ['x' * 100], mergeSpan: true);
    final ctx = buildEditorContext([node]);
    var r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(
            0, RichTextNodePosition(0, 10), RichTextNodePosition(0, 20)),
        EventType.italic,
        ctx));
    var n1 = r1.node as RichTextNode;
    var c1 = r1.cursor as SelectingNodeCursor;
    assert(n1.spans.length == 3);
    assert(!n1.spans.first.tags.contains(EventType.italic.name));
    assert(!n1.spans.last.tags.contains(EventType.italic.name));
    assert(n1.spans[1].tags.contains(EventType.italic.name));
    assert(n1.getOffset(c1.left as RichTextNodePosition) == 10);
    assert(n1.getOffset(c1.right as RichTextNodePosition) == 20);

    var r2 = n1.onSelect(SelectingData(
        SelectingNodeCursor(0, n1.beginPosition, n1.endPosition),
        EventType.italic,
        ctx));
    var n2 = r2.node as RichTextNode;
    var c2 = r2.cursor as SelectingNodeCursor;
    assert(n2.spans.length == 1);
    assert(n2.spans.first.tags.contains(EventType.italic.name));
    assert(c2.left == n2.beginPosition);
    assert(c2.right == n2.endPosition);

    var r3 = n2.onSelect(SelectingData(
        SelectingNodeCursor(0, n2.beginPosition, n2.endPosition),
        EventType.italic,
        ctx,
        extras: StyleExtra(true, null)));
    var n3 = r3.node as RichTextNode;
    var c3 = r3.cursor as SelectingNodeCursor;
    assert(n3.spans.length == 1);
    assert(n3.spans.first.tags.isEmpty);
    assert(c3.left == n3.beginPosition);
    assert(c3.right == n3.endPosition);
  });

  test('onEdit-paste', () {
    final node = basicTextNode(mergeSpan: true);
    final ctx = buildEditorContext([node]);
    expect(
        () => node.onEdit(EditingData(
            EditingCursor(0, node.beginPosition), EventType.paste, ctx,
            extras: <EditorNode>[])),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
    var r1 = node.onEdit(EditingData(
        EditingCursor(0, node.endPosition), EventType.paste, ctx,
        extras: [node]));
    var n1 = r1.node as RichTextNode;
    var c1 = r1.cursor as EditingCursor;
    assert(n1.spans.length == 1);
    assert(c1.position == n1.endPosition);

    expect(
        () => node.onEdit(EditingData(
            EditingCursor(0, node.beginPosition), EventType.paste, ctx,
            extras: <EditorNode>[TestEditorNode()])),
        throwsA(const TypeMatcher<PasteToCreateMoreNodesException>()));

    try {
      basicTextNode(texts: ['1' * 5]).onEdit(EditingData(
          EditingCursor(0, RichTextNodePosition(0, 3)), EventType.paste, ctx,
          extras: [
            basicTextNode(texts: ['0' * 5]),
            basicTextNode(texts: ['2' * 5])
          ]));
    } on PasteToCreateMoreNodesException catch (e) {
      final nodes = e.nodes;
      final p = e.position;
      assert(nodes.length == 2);
      assert(p is RichTextNodePosition);
      assert(p == RichTextNodePosition(0, 5));
      assert(nodes.first.text == '1' * 3 + '0' * 5);
      assert(nodes.last.text == '2' * 5 + '1' * 2);
    }

    try {
      basicTextNode(texts: ['1' * 5]).onEdit(EditingData(
          EditingCursor(0, RichTextNodePosition(0, 3)), EventType.paste, ctx,
          extras: [
            TestEditorNode(),
            TestEditorNode(),
            TestEditorNode(),
          ]));
    } on PasteToCreateMoreNodesException catch (e) {
      final nodes = e.nodes;
      assert(nodes.length == 5);
      for (var i = 1; i < 4; ++i) {
        var o = nodes[i];
        assert(o is TestEditorNode);
      }
      assert(nodes.first is RichTextNode);
      assert(nodes.last is RichTextNode);
      assert(nodes.first.text == '1' * 3);
      assert(nodes.last.text == '1' * 2);
    }
  });

  test('onEdit-paste', () {
    final node = basicTextNode(mergeSpan: true);
    final ctx = buildEditorContext([node]);
    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(0, node.beginPosition, node.endPosition),
            EventType.paste,
            ctx,
            extras: <EditorNode>[])),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
    var r1 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, node.beginPosition, node.endPosition),
        EventType.paste,
        ctx,
        extras: [node]));
    var n1 = r1.node as RichTextNode;
    var c1 = r1.cursor as EditingCursor;
    assert(n1.spans.length == 1);
    assert(c1.position == node.endPosition);

    try {
      basicTextNode(texts: ['1' * 5]).onSelect(SelectingData(
          SelectingNodeCursor(
              0, RichTextNodePosition(0, 1), RichTextNodePosition(0, 4)),
          EventType.paste,
          ctx,
          extras: [
            basicTextNode(texts: ['0' * 5]),
            basicTextNode(texts: ['2' * 5])
          ]));
    } on PasteToCreateMoreNodesException catch (e) {
      assert(e.nodes.length == 2);
      assert(e.nodes.first.text == '1${'0' * 5}');
      assert(e.nodes.last.text == '${'2' * 5}1');
    }

    try {
      basicTextNode(texts: ['1' * 5]).onSelect(SelectingData(
          SelectingNodeCursor(
              0, RichTextNodePosition(0, 1), RichTextNodePosition(0, 4)),
          EventType.paste,
          ctx,
          extras: [TestEditorNode()]));
    } on PasteToCreateMoreNodesException catch (e) {
      assert(e.nodes.length == 3);
      assert(e.nodes.first.text == '1');
      assert(e.nodes.last.text == '1');
      assert(e.nodes[1] is TestEditorNode);
    }

    try {
      basicTextNode(texts: ['1' * 5]).onSelect(SelectingData(
          SelectingNodeCursor(
              0, RichTextNodePosition(0, 1), RichTextNodePosition(0, 4)),
          EventType.paste,
          ctx,
          extras: [
            TestEditorNode(),
            TestEditorNode(),
            TestEditorNode(),
          ]));
    } on PasteToCreateMoreNodesException catch (e) {
      assert(e.nodes.length == 5);
      assert(e.nodes.first.text == '1');
      assert(e.nodes.last.text == '1');
      for (var i = 1; i < 4; ++i) {
        assert(e.nodes[i] is TestEditorNode);
      }
    }
  });

  test('onEdit-typing', () {
    final node = basicTextNode(texts: ['aaaaaa']);
    final ctx = buildEditorContext([node]);
    expect(
        () => node.onEdit(EditingData(
            EditingCursor(0, node.beginPosition), EventType.typing, ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));

    var r1 = node.onEdit(EditingData(
        EditingCursor(0, node.endPosition), EventType.typing, ctx,
        extras: TextEditingValue(
            text: 'bbb', selection: TextSelection.collapsed(offset: 3))));
    var n1 = r1.node as RichTextNode;
    var c1 = r1.cursor as EditingCursor;
    assert(n1.text == '${node.text}bbb');
    assert(c1.position == RichTextNodePosition(0, 9));

    var r2 = node.onEdit(EditingData(
        EditingCursor(0, RichTextNodePosition(0, 3)), EventType.typing, ctx,
        extras: TextEditingValue(
            text: 'bbb', selection: TextSelection.collapsed(offset: 3))));
    var n2 = r2.node as RichTextNode;
    var c2 = r2.cursor as EditingCursor;
    assert(n2.text == 'aaabbbaaa');
    assert(c2.position == RichTextNodePosition(0, 6));

    for (var key in string2generator.keys) {
      expect(
          () => basicTextNode(texts: [key]).onEdit(EditingData(
              EditingCursor(0, RichTextNodePosition(0, key.length)),
              EventType.typing,
              ctx,
              extras: TextEditingValue(
                  text: ' ', selection: TextSelection.collapsed(offset: 1)))),
          throwsA(const TypeMatcher<TypingToChangeNodeException>()));
    }

    for (var i = 0; i < 20; ++i) {
      final index = '$i.';
      expect(
          () => basicTextNode(texts: [index]).onEdit(EditingData(
              EditingCursor(0, RichTextNodePosition(0, index.length)),
              EventType.typing,
              ctx,
              extras: TextEditingValue(
                  text: ' ', selection: TextSelection.collapsed(offset: 1)))),
          throwsA(const TypeMatcher<TypingToChangeNodeException>()));
    }

    expect(
        () => basicTextNode(texts: ['']).onEdit(EditingData(
            EditingCursor(0, RichTextNodePosition(0, 0)), EventType.typing, ctx,
            extras: TextEditingValue(
                text: '/', selection: TextSelection.collapsed(offset: 1)))),
        throwsA(const TypeMatcher<TypingRequiredOptionalMenuException>()));
  });

  test('onSelect-typing', () {
    final node = basicTextNode(texts: ['123456789']);
    final ctx = buildEditorContext([node]);

    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(
                0, RichTextNodePosition(0, 4), RichTextNodePosition(0, 7)),
            EventType.typing,
            ctx,
            extras: TextEditingValue(
                text: 'abcde', selection: TextSelection.collapsed(offset: 5)))),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
  });
}
