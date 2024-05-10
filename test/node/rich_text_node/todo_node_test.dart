import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/node/rich_text/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/const_texts.dart';
import '../config/test_node_context.dart';

void main() {
  test('from', () {
    var node =
        TodoNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    assert(node.spans.length == constTexts.length);
    for (var i = 0; i < node.spans.length; ++i) {
      final span = node.spans[i];
      final text = constTexts[i];
      assert(span.text == text);
    }

    final newNode = node.from([]);
    assert(newNode.isEmpty);
    assert(newNode.spans.length == 1);
  });

  test('toJson', () {
    var node =
        TodoNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    final json = node.toJson();
    assert(json['type'] == 'TodoNode');
  });

  testWidgets('build', (tester) async {
    var node =
        TodoNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());

    var widget = Builder(
        builder: (c) => node
            .from(node.spans, depth: 1)
            .build(TestNodeContext(), NodeBuildParam.empty(), c));
    await tester.pumpWidget(Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ));

    widget = Builder(
        builder: (c) => node
            .from(node.spans, depth: 2)
            .build(TestNodeContext(), NodeBuildParam.empty(), c));
    await tester.pumpWidget(Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ));

    widget = Builder(
        builder: (c) => node
            .from(node.spans, depth: 3)
            .build(TestNodeContext(), NodeBuildParam.empty(), c));
    await tester.pumpWidget(Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ));

    widget = Builder(
        builder: (c) => node
            .from(node.spans, depth: 4)
            .build(TestNodeContext(), NodeBuildParam.empty(), c));
    await tester.pumpWidget(Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ));
  });
}
