import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/shortcuts/tab.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';

void main() {
  test('tab-editing', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(EditingCursor(0, ctx.nodes.first.beginPosition));
    TabAction(ActionOperator(ctx)).invoke(TabIntent());
    assert(ctx.nodes.first.depth == 1);

    ShiftTabAction(ActionOperator(ctx)).invoke(ShiftTabIntent());
    assert(ctx.nodes.first.depth == 0);
    ShiftTabAction(ActionOperator(ctx)).invoke(ShiftTabIntent());
    assert(ctx.nodes.first.depth == 0);
  });


  test('tab-selecting-node', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(SelectingNodeCursor(
        0, ctx.nodes.first.beginPosition, ctx.nodes.first.endPosition));
    TabAction(ActionOperator(ctx)).invoke(TabIntent());
    assert(ctx.nodes.first.depth == 1);

    ShiftTabAction(ActionOperator(ctx)).invoke(ShiftTabIntent());
    assert(ctx.nodes.first.depth == 0);
  });

  test('tab-selecting-nodes', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 10)], depth: 1),
      RichTextNode.from([RichTextSpan(text: 'c' * 10)], depth: 2),
    ]);
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, ctx.nodes.first.beginPosition),
        EditingCursor(2, ctx.nodes.last.endPosition)));
    TabAction(ActionOperator(ctx)).invoke(TabIntent());
    assert(ctx.nodes.first.depth == 1);
    assert(ctx.nodes.last.depth == 3);
    TabAction(ActionOperator(ctx)).invoke(TabIntent());
    assert(ctx.nodes.first.depth == 1);
    assert(ctx.nodes.last.depth == 3);

    ShiftTabAction(ActionOperator(ctx)).invoke(ShiftTabIntent());
    assert(ctx.nodes.first.depth == 0);
    assert(ctx.nodes.last.depth == 2);
    ShiftTabAction(ActionOperator(ctx)).invoke(ShiftTabIntent());
    assert(ctx.nodes.last.depth == 1);

  });

}
