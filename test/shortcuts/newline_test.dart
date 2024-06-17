import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/node/rich_text/unordered.dart';
import 'package:crayon/editor/shortcuts/newline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';

void main() {
  test('newline-editing', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(EditingCursor(0, ctx.nodes.last.endPosition));
    NewlineAction(ActionOperator(ctx)).invoke(NewlineIntent());
    assert(ctx.nodes.length == 2);
    assert(ctx.nodes.last.text.isEmpty);

    ctx = buildEditorContext([
      UnorderedNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(EditingCursor(0, RichTextNodePosition(0, 5)));
    NewlineAction(ActionOperator(ctx)).invoke(NewlineIntent());
    assert(ctx.nodes.length == 2);
    assert(ctx.nodes.last.text.length == 5);
    assert(ctx.nodes.last is UnorderedNode);
  });

  test('newline-selecting-node', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(SelectingNodeCursor(
        0, RichTextNodePosition.zero(), RichTextNodePosition(0, 5)));
    NewlineAction(ActionOperator(ctx)).invoke(NewlineIntent());
    assert(ctx.nodes.length == 2);
    assert(ctx.nodes.first.text.isEmpty);
    assert(ctx.nodes.last.text.length == 5);

    ctx = buildEditorContext([
      UnorderedNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(SelectingNodeCursor(
        0, RichTextNodePosition.zero(), RichTextNodePosition(0, 5)));
    NewlineAction(ActionOperator(ctx)).invoke(NewlineIntent());
    assert(ctx.nodes.length == 2);
    assert(ctx.nodes.first.text.isEmpty);
    assert(ctx.nodes.last.text.length == 5);
    assert(ctx.nodes.last is UnorderedNode);
  });

  test('newline-selecting-nodes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 10)], depth: 10),
      RichTextNode.from([RichTextSpan(text: 'c' * 10)]),
    ]);
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, RichTextNodePosition.zero()),
        EditingCursor(1, RichTextNodePosition(0, 5))));
    NewlineAction(ActionOperator(ctx)).invoke(NewlineIntent());
    assert(ctx.nodes.length == 3);
    assert(ctx.nodes.first.text.isEmpty);
    assert(ctx.nodes[1].text.length == 5);
    assert(ctx.nodes.last.text.length == 10);
    assert(ctx.nodes[1].depth == 1);
  });
}
