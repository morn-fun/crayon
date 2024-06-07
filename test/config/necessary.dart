import 'package:crayon/editor/core/command_invoker.dart';
import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/core/editor_controller.dart';
import 'package:crayon/editor/core/entry_manager.dart';
import 'package:crayon/editor/core/input_manager.dart';
import 'package:crayon/editor/core/logger.dart';
import 'package:crayon/editor/exception/command.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/divider/divider.dart';

import '../node/code_block/code_block_test.dart';
import '../node/rich_text/rich_text_test.dart';
import '../node/table/table_test.dart';

EditorContext buildEditorContext(List<EditorNode> nodes) {
  final testInvoker = CommandInvoker();
  late EditorContext context;
  final InputManager testInputManager = InputManager(
      contextGetter: () => context,
      onCommand: (c) {
        try {
          testInvoker.execute(c, context);
        } on PerformCommandException catch (e) {
          logger.e('$e');
        }
      },
      focusCall: () {},
      onOptionalMenu: (s) {});
  context = EditorContext(RichEditorController.fromNodes(nodes),
      testInputManager, testInvoker, EntryManager((v) {}, (v) {}));
  return context;
}

List<EditorNode> basicNodes() {
  return [
    basicTextNode(texts: ['a * 100']),
    basicTableNode(),
    DividerNode(),
    basicCodeBlockNode(),
    DividerNode()
  ];
}
