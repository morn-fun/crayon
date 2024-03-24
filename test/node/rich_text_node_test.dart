
import 'package:flutter_test/flutter_test.dart';
import 'package:pre_editor/editor/cursor/rich_text_cursor.dart';
import 'package:pre_editor/editor/exception/editor_node_exception.dart';
import 'package:pre_editor/editor/node/rich_text_node/rich_text_node.dart';
import 'package:pre_editor/editor/node/rich_text_node/rich_text_span.dart';

void main() {
  const constTexts = [
    'Thank you - 谢谢',
    'How are you? - 你好吗？',
    'I love you - 我爱你',
    'What\'s your name? - 你叫什么名字？',
    'Where are you from? - 你从哪里来？',
    'Excuse me - 对不起 / 不好意思',
    'How much is it? - 多少钱？',
    'I\'m sorry - 对不起',
    'Good morning - 早上好',
    'I don\'t understand - 我不懂',
  ];

  RichTextNode basicNode({List<String>? texts}) {
    final spans = <RichTextSpan>[];
    for (var text in (texts ?? constTexts)) {
      final isFirst = spans.isEmpty;
      spans.add(
          RichTextSpan(text: text, offset: isFirst ? 0 : spans.last.endOffset));
    }

    return RichTextNode.from(spans);
  }

  test('frontPartNode', () {
    final newNode = basicNode();
    final node1 = newNode.frontPartNode(RichTextNodePosition(4, 5));
    assert(node1.getSpan(0).text == constTexts[0]);
    assert(node1.getSpan(1).text == constTexts[1]);
    assert(node1.getSpan(2).text == constTexts[2]);
    assert(node1.getSpan(3).text == constTexts[3]);
    assert(node1.getSpan(4).text != constTexts[4]);
    assert(node1.getSpan(0).offset == newNode.getSpan(0).offset);
    assert(node1.getSpan(1).offset == newNode.getSpan(1).offset);
    assert(node1.getSpan(2).offset == newNode.getSpan(2).offset);
    assert(node1.getSpan(3).offset == newNode.getSpan(3).offset);
    for (var i = 1; i < node1.spans.length; ++i) {
      var currentSpan = node1.getSpan(i);
      assert(currentSpan.offset == node1.getSpan(i - 1).endOffset);
    }

    assert(newNode.frontPartNode(newNode.beginPosition).spans.length == 1);

    final node2 = newNode.frontPartNode(RichTextNodePosition(1, 0));
    assert(node2.spans.length == 2);
    assert(node2.spans.last.textLength == 0);

    final node3 =
        newNode.frontPartNode(RichTextNodePosition(0, constTexts[0].length));
    assert(node3.spans.length == 1);
    assert(node3.spans.last.text == constTexts[0]);
  });

  test('rearPartNode', () {
    final newNode = basicNode();
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
    assert(node3.spans.length == 2);
    assert(node3.spans.first.textLength == 0);
    assert(node3.spans.last.text == node1.spans.last.text);
  });

  test('locateSpanIndex', () {
    final newNode = basicNode();
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
    final newNode = basicNode();
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
    final newNode = basicNode();
    final node1 = newNode.merge(basicNode());
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
  });

  test('update', () {
    final newNode = basicNode();
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
    final newNode = basicNode();
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

    final node7 = RichTextNode.empty()
        .replace(RichTextNodePosition.zero(), RichTextNodePosition.zero(), []);
    assert(node7.spans.length == 1);
  });

  test('delete', () {
    final newNode = basicNode(texts: ['abc', 'xyz', 'l']);
    final np1 = newNode
        .delete(RichTextNodePosition(0, newNode.spans.first.textLength))!;
    assert((np1.position as RichTextNodePosition).index == 0);
    assert((np1.position as RichTextNodePosition).offset ==
        newNode.spans.first.textLength - 1);
    final node1 = np1.node as RichTextNode;
    assert(node1.spans.first.text == 'ab');
    expect(() => newNode.delete(RichTextNodePosition(0, 0)),
        throwsA(const TypeMatcher<DeleteRequiresNewLineException>()));

    final np2 = newNode.delete(RichTextNodePosition(0, 1))!;
    final node2 = np2.node as RichTextNode;
    assert(node2.spans.first.text == 'bc');
    assert((np2.position as RichTextNodePosition).offset == 0);

    final np3 = newNode.delete(RichTextNodePosition(1, 0))!;
    assert(np3.position ==
        RichTextNodePosition(0, newNode.spans.first.textLength - 1));
    final node3 = np3.node as RichTextNode;
    assert(node3.spans.first.text == 'ab');

    final np4 = newNode.delete(RichTextNodePosition(2, 1))!;
    assert((np4.position as RichTextNodePosition).index == 1);
    assert((np4.position as RichTextNodePosition).offset ==
        newNode.spans[1].textLength);
    final node4 = np4.node as RichTextNode;
    assert(node4.spans.length == 1);
  });

  test('selectingTextSpan', () {
    final newNode = basicNode(texts: ['aaaaaa', 'bbbbbb', 'cccccc']);
    final textSpan = newNode.selectingTextSpan(
        RichTextNodePosition(1, 0), RichTextNodePosition(2, 0));
    print('textSpan:$textSpan');
  });
}
