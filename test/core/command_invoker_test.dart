import 'package:crayon/editor/command/modification.dart';
import 'package:crayon/editor/command/replacement.dart';
import 'package:crayon/editor/core/command_invoker.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/code_block.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/cursor/table.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/code_block/code_block.dart';
import 'package:crayon/editor/node/rich_text/head.dart';
import 'package:crayon/editor/node/table/table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';
import '../node/rich_text/rich_text_test.dart';
import '../node/table/table_test.dart';

void main() {
  test('execute', () async {
    final invoker = CommandInvoker();
    var ctx = buildEditorContext([basicTextNode()]);
    invoker.execute(
        ModifyNode(NodeWithCursor(CodeBlockNode.from([]),
            EditingCursor(0, CodeBlockPosition.zero()))),
        ctx);
    assert(ctx.nodes.length == 1);
    assert(ctx.nodes.first is CodeBlockNode);
    await Future.delayed(Duration(seconds: 1), () {
      invoker.execute(
          ModifyNode(NodeWithCursor(
              basicTableNode(), EditingCursor(0, TablePosition.zero()))),
          ctx);
      assert(ctx.nodes.length == 1);
      assert(ctx.nodes.first is TableNode);
    });
    invoker.execute(
        ModifyNode(NodeWithCursor(
            H1Node.from([]), EditingCursor(0, RichTextNodePosition.zero()))),
        ctx,
        noThrottle: true);
    assert(ctx.nodes.length == 1);
    assert(ctx.nodes.first is H1Node);
  });

  test('undo-redo', () {
    final invoker = CommandInvoker();
    var ctx = buildEditorContext([basicTextNode()]);
    for (var i = 0; i < 101; ++i) {
      invoker.execute(AddRichTextNode(basicTextNode()), ctx, noThrottle: true);
    }
    for (var i = 0; i < 100; ++i) {
      invoker.undo(ctx.controller);
    }
    for (var i = 0; i < 100; ++i) {
      invoker.redo(ctx.controller);
    }
  });

  test('dispose', () {
    final invoker = CommandInvoker();
    invoker.dispose();
  });
}
