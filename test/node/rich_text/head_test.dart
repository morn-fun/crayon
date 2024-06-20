import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/rich_text/head.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../config/const_texts.dart';
import '../../config/test_node_context.dart';

void main() {
  test('from', () {
    void assetNode(HeadNode node) {
      assert(node.spans.length == constTexts.length);
      for (var i = 0; i < node.spans.length; ++i) {
        final span = node.spans[i];
        final text = constTexts[i];
        assert(span.text == text);
      }

      final newNode = node.from([]);
      assert(newNode.isEmpty);
      assert(newNode.spans.length == 1);
    }

    assetNode(
        H1Node.from(constTexts.map((e) => RichTextSpan(text: e)).toList()));
    assetNode(
        H2Node.from(constTexts.map((e) => RichTextSpan(text: e)).toList()));
    assetNode(
        H3Node.from(constTexts.map((e) => RichTextSpan(text: e)).toList()));
  });

  test('toJson', () {
    HeadNode node =
        H1Node.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    var json = node.toJson();
    assert(json['type'] == 'H1Node');

    node = H2Node.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    json = node.toJson();
    assert(json['type'] == 'H2Node');

    node = H3Node.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    json = node.toJson();
    assert(json['type'] == 'H3Node');
  });

  test('onEdit', () {
    H1Node node =
        H1Node.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    expect(
        () => node.onEdit(EditingData(RichTextNodePosition.zero().toCursor(0),
            EventType.newline, TestNodeContext())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    var np = node.from([]).onEdit(EditingData(
        RichTextNodePosition.zero().toCursor(0),
        EventType.increaseDepth,
        TestNodeContext()));
    assert(np.node.depth - node.depth == 1);
  });

  test('onSelect', () {
    H1Node node =
        H1Node.from(constTexts.map((e) => RichTextSpan(text: e)).toList());

    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(
                0, RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
            EventType.newline,
            TestNodeContext())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    var np = node.from([]).onSelect(SelectingData(
        SelectingNodeCursor(
            0, RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
        EventType.increaseDepth,
        TestNodeContext()));
    assert(np.node.depth > node.depth);
  });

  testWidgets('build', (tester) async {
    HeadNode node =
        H1Node.from(constTexts.map((e) => RichTextSpan(text: e)).toList());

    var widget = Builder(
        builder: (c) => node
            .from(node.spans, depth: 1)
            .build(TestNodeContext(), NodeBuildParam.empty(), c));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ));

    widget = Builder(
        builder: (c) => H2Node.from(node.spans, depth: 1)
            .build(TestNodeContext(), NodeBuildParam.empty(), c));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ));

    widget = Builder(
        builder: (c) => H3Node.from(node.spans, depth: 1)
            .build(TestNodeContext(), NodeBuildParam.empty(), c));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ));
  });
}
