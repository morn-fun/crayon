import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/code_block.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/node/code_block/code_block.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/shortcuts/select_all.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';

void main() {
  test('select-all-editing', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      CodeBlockNode.from(['b' * 10]),
      RichTextNode.from([RichTextSpan(text: 'c' * 10)]),
    ]);
    ctx.onCursor(EditingCursor(1, CodeBlockPosition.zero()));

    SelectAllAction(ActionOperator(ctx)).invoke(SelectAllIntent());
    var cursor = (ctx.cursor as SelectingNodeCursor).as<CodeBlockPosition>();
    assert(!cursor.begin.atEdge);
    assert(!cursor.end.atEdge);

    SelectAllAction(ActionOperator(ctx)).invoke(SelectAllIntent());
    cursor = (ctx.cursor as SelectingNodeCursor).as<CodeBlockPosition>();
    assert(cursor.begin.atEdge);
    assert(cursor.end.atEdge);

    SelectAllAction(ActionOperator(ctx)).invoke(SelectAllIntent());
    assert(ctx.cursor is SelectingNodesCursor);

    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: '')]),
      CodeBlockNode.from(['b' * 10]),
      RichTextNode.from([RichTextSpan(text: 'c' * 10)]),
    ]);
    ctx.onCursor(EditingCursor(0, RichTextNodePosition.zero()));
    SelectAllAction(ActionOperator(ctx)).invoke(SelectAllIntent());
    assert(ctx.cursor is SelectingNodesCursor);
    assert(ctx.cursor == ctx.selectAllCursor);

  });

  test('select-all-selecting-nodes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: '')]),
      CodeBlockNode.from(['b' * 10]),
      RichTextNode.from([RichTextSpan(text: 'c' * 10)]),
    ]);
    ctx.onCursor(SelectingNodesCursor(
      EditingCursor(0, RichTextNodePosition.zero()),
      EditingCursor(2, RichTextNodePosition.zero()),
    ));

    SelectAllAction(ActionOperator(ctx)).invoke(SelectAllIntent());
    assert(ctx.cursor is SelectingNodesCursor);
    assert(ctx.cursor == ctx.selectAllCursor);
  });
}
