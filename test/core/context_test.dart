import 'package:crayon/editor/command/replacement.dart';
import 'package:crayon/editor/core/editor_controller.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/table.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:crayon/editor/node/code_block/code_block.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/table/generator/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';
import '../node/rich_text/rich_text_test.dart';
import '../node/table/table_test.dart';

void onCatch(VoidCallback callback) {
  try {
    callback.call();
  } catch (e) {
    print('$e');
  }
}

void main() {
  test('undo-redo', () {
    var ctx = buildEditorContext([basicTextNode()]);
    ctx.execute(AddRichTextNode(basicTextNode()));
    onCatch(() => ctx.undo());
    onCatch(() => ctx.undo());
    onCatch(() => ctx.redo());
    onCatch(() => ctx.redo());
  });

  test('others-test', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([basicTextNode()]);
    ctx.onCursorOffset(EditingOffset(Offset.zero, 10, ctx.nodes.first.id));
    ctx.onNode(CodeBlockNode.from([]), 0);
    assert(ctx.nodes.first is CodeBlockNode);
    final ctx2 = ctx.newOperator(ctx.nodes, ctx.cursor);
    assert(ctx2.hashCode == ctx.hashCode);
    ctx.removeEntry();
    ctx.scrollTo(0);
    ctx.restartInput();
  });

  test('table-context', () {
    final tableNode = basicTableNode();
    var baseContext = buildEditorContext([tableNode]);
    var ctx = buildTableCellNodeContext(
        baseContext, CellPosition.zero(), tableNode, baseContext.cursor, 0);
    final cursor = ctx.selectAllCursor;
    assert(cursor is SelectingNodesCursor);
    final ctx2 = ctx.newOperator(ctx.nodes, ctx.cursor);
    assert(ctx2.hashCode != ctx.hashCode);

    ctx = buildTableCellNodeContext(
        baseContext, CellPosition.zero(), tableNode, NoneCursor(), 0);
    assert(ctx.cursor is NoneCursor);
    ctx.onCursor(NoneCursor());
    expect(
        () =>
            ctx.operation.call(Update(0, RichTextNode.from([]), NoneCursor())),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
  });
}
