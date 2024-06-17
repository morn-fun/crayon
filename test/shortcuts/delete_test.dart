import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/code_block.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/node/code_block/code_block.dart';
import 'package:crayon/editor/node/rich_text/head.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/node/rich_text/unordered.dart';
import 'package:crayon/editor/shortcuts/delete.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';
import '../node/table/table_test.dart';

void main() {
  test('delete-editing', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      H1Node.from([RichTextSpan(text: 'b' * 10)]),
      CodeBlockNode.from(['c' * 10]),
      basicTableNode(),
      UnorderedNode.from([RichTextSpan(text: 'd' * 10)]),
    ]);
    ctx.onCursor(EditingCursor(4, ctx.nodes.last.endPosition));
    int i = 0;
    while (i < 30) {
      DeleteAction(ActionOperator(ctx)).invoke(DeleteIntent());
      i++;
    }
  });

  test('delete-selecting-node', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      H1Node.from([RichTextSpan(text: 'b' * 10)]),
      CodeBlockNode.from(['c' * 10]),
      UnorderedNode.from([RichTextSpan(text: 'd' * 10)]),
    ]);
    ctx.onCursor(SelectingNodeCursor(
        2, CodeBlockPosition(0, 0), CodeBlockPosition(0, 5)));
    int i = 0;
    while (i < 5) {
      DeleteAction(ActionOperator(ctx)).invoke(DeleteIntent());
      i++;
    }
  });

  test('delete-selecting-nodes', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      H1Node.from([RichTextSpan(text: 'b' * 10)]),
      CodeBlockNode.from(['c' * 10]),
      UnorderedNode.from([RichTextSpan(text: 'd' * 10)]),
    ]);
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(0, RichTextNodePosition.zero()),
        EditingCursor(2, CodeBlockPosition(0, 5))));
    int i = 0;
    while (i < 5) {
      DeleteAction(ActionOperator(ctx)).invoke(DeleteIntent());
      i++;
    }

    ctx = buildEditorContext([
      RichTextNode.from([RichTextSpan(text: 'a' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'b' * 10)]),
      RichTextNode.from([RichTextSpan(text: 'd' * 10)]),
    ]);
    ctx.onCursor(SelectingNodesCursor(
        EditingCursor(1, RichTextNodePosition.zero()),
        EditingCursor(2, RichTextNodePosition.zero())));
    i = 0;
    while (i < 5) {
      DeleteAction(ActionOperator(ctx)).invoke(DeleteIntent());
      i++;
    }
  });
}
