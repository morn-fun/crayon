import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/shortcuts/styles.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';

void main() {
  test('italic', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(SelectingNodeCursor(
        0, ctx.nodes.first.beginPosition, ctx.nodes.first.endPosition));
    ItalicAction(ActionOperator(ctx)).invoke(ItalicIntent());
    var n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(n1.spans.first.tags.contains(RichTextTag.italic.name));

    ItalicAction(ActionOperator(ctx)).invoke(ItalicIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(!n1.spans.first.tags.contains(RichTextTag.italic.name));


    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'c' * 10)]),
    ]);
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, ctx.nodes.first.beginPosition),
        EditingCursor(2, ctx.nodes.last.endPosition)));
    ItalicAction(ActionOperator(ctx)).invoke(ItalicIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(n1.spans.first.tags.contains(RichTextTag.italic.name));

    ItalicAction(ActionOperator(ctx)).invoke(ItalicIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(!n1.spans.first.tags.contains(RichTextTag.italic.name));
  });

  test('bold', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(SelectingNodeCursor(
        0, ctx.nodes.first.beginPosition, ctx.nodes.first.endPosition));
    BoldAction(ActionOperator(ctx)).invoke(BoldIntent());
    var n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(n1.spans.first.tags.contains(RichTextTag.bold.name));

    BoldAction(ActionOperator(ctx)).invoke(BoldIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(!n1.spans.first.tags.contains(RichTextTag.bold.name));


    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'c' * 10)]),
    ]);
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, ctx.nodes.first.beginPosition),
        EditingCursor(2, ctx.nodes.last.endPosition)));
    BoldAction(ActionOperator(ctx)).invoke(BoldIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(n1.spans.first.tags.contains(RichTextTag.bold.name));

    BoldAction(ActionOperator(ctx)).invoke(BoldIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(!n1.spans.first.tags.contains(RichTextTag.bold.name));
  });

  test('underline', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(SelectingNodeCursor(
        0, ctx.nodes.first.beginPosition, ctx.nodes.first.endPosition));
    UnderlineAction(ActionOperator(ctx)).invoke(UnderlineIntent());
    var n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(n1.spans.first.tags.contains(RichTextTag.underline.name));

    UnderlineAction(ActionOperator(ctx)).invoke(UnderlineIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(!n1.spans.first.tags.contains(RichTextTag.underline.name));


    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'c' * 10)]),
    ]);
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, ctx.nodes.first.beginPosition),
        EditingCursor(2, ctx.nodes.last.endPosition)));
    UnderlineAction(ActionOperator(ctx)).invoke(UnderlineIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(n1.spans.first.tags.contains(RichTextTag.underline.name));

    UnderlineAction(ActionOperator(ctx)).invoke(UnderlineIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(!n1.spans.first.tags.contains(RichTextTag.underline.name));
  });

  test('lineThrough', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
    ]);
    ctx.onCursor(SelectingNodeCursor(
        0, ctx.nodes.first.beginPosition, ctx.nodes.first.endPosition));
    LineThroughAction(ActionOperator(ctx)).invoke(LineThroughIntent());
    var n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(n1.spans.first.tags.contains(RichTextTag.lineThrough.name));

    LineThroughAction(ActionOperator(ctx)).invoke(LineThroughIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(!n1.spans.first.tags.contains(RichTextTag.lineThrough.name));


    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'c' * 10)]),
    ]);
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, ctx.nodes.first.beginPosition),
        EditingCursor(2, ctx.nodes.last.endPosition)));
    LineThroughAction(ActionOperator(ctx)).invoke(LineThroughIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(n1.spans.first.tags.contains(RichTextTag.lineThrough.name));

    LineThroughAction(ActionOperator(ctx)).invoke(LineThroughIntent());
    n1 = ctx.nodes.first as RichTextNode;
    assert(n1.spans.length == 1);
    assert(!n1.spans.first.tags.contains(RichTextTag.lineThrough.name));
  });
}
