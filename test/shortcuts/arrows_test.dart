import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/node/divider/divider.dart';
import 'package:crayon/editor/shortcuts/arrows/arrows.dart';
import 'package:crayon/editor/shortcuts/arrows/line_arrow.dart';
import 'package:crayon/editor/shortcuts/arrows/selection_arrow.dart';
import 'package:crayon/editor/shortcuts/arrows/selection_word_arrow.dart';
import 'package:crayon/editor/shortcuts/arrows/single_arrow.dart';
import 'package:crayon/editor/shortcuts/arrows/word_arrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/necessary.dart';
import '../config/test_rich_editor.dart';
import '../node/code_block/code_block_test.dart';
import '../node/rich_text/rich_text_test.dart';

void runCycle(VoidCallback callback, {int times = 30}) {
  for (var i = 0; i < times; ++i) {
    callback.call();
  }
}

void main() {
  testWidgets('arrows-editing', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    var ctx = buildEditorContext([
      basicTextNode(texts: ['a * 20']),
      DividerNode(),
      basicCodeBlockNode(),
      DividerNode(),
    ]);
    var widget = Builder(builder: (c) => TestRichEditor(ctx));
    await tester.pumpWidget(Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ));
    ctx.onCursor(EditingCursor(0, ctx.nodes.first.beginPosition));
    runCycle(
        () => ArrowRightAction(ActionOperator(ctx)).invoke(ArrowRightIntent()));
    runCycle(
        () => ArrowLeftAction(ActionOperator(ctx)).invoke(ArrowLeftIntent()));
    runCycle(
        () => ArrowDownAction(ActionOperator(ctx)).invoke(ArrowDownIntent()));
    runCycle(() => ArrowUpAction(ActionOperator(ctx)).invoke(ArrowUpIntent()));
    runCycle(() => ArrowLineBeginAction(ActionOperator(ctx))
        .invoke(ArrowLineBeginIntent()));
    runCycle(() =>
        ArrowLineEndAction(ActionOperator(ctx)).invoke(ArrowLineEndIntent()));
    runCycle(() => ArrowSelectionLeftAction(ActionOperator(ctx))
        .invoke(ArrowSelectionLeftIntent()));
    runCycle(() => ArrowSelectionRightAction(ActionOperator(ctx))
        .invoke(ArrowSelectionRightIntent()));
    runCycle(() => ArrowSelectionUpAction(ActionOperator(ctx))
        .invoke(ArrowSelectionUpIntent()));
    runCycle(() => ArrowSelectionDownAction(ActionOperator(ctx))
        .invoke(ArrowSelectionDownIntent()));
    runCycle(() => ArrowSelectionWordLastAction(ActionOperator(ctx))
        .invoke(ArrowSelectionWordLastIntent()));
    runCycle(() => ArrowSelectionWordNextAction(ActionOperator(ctx))
        .invoke(ArrowSelectionWordNextIntent()));
    runCycle(() =>
        ArrowWordLastAction(ActionOperator(ctx)).invoke(ArrowWordLastIntent()));
    runCycle(() =>
        ArrowWordNextAction(ActionOperator(ctx)).invoke(ArrowWordNextIntent()));
  });
}
