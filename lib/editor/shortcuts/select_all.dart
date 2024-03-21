import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class SelectAllAction extends ContextAction<SelectAllIntent> {
  final EditorContext editorContext;

  SelectAllAction(this.editorContext);

  @override
  void invoke(SelectAllIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final controller = editorContext.controller;
    final cursor = editorContext.cursor;
    if (cursor is EditingCursor) {
      final node = controller.getNode(cursor.index);
      controller.updateCursor(SelectingNodeCursor(
          cursor.index, node.beginPosition, node.endPosition));
    } else if ((cursor is SelectingNodeCursor && controller.nodeLength > 1) ||
        (cursor is SelectingNodesCursor)) {
      final allNodesCursor = SelectingNodesCursor(
          IndexWithPosition(0, controller.firstNode.beginPosition),
          IndexWithPosition(
              controller.nodeLength - 1, controller.lastNode.endPosition));
      if (cursor == allNodesCursor) return;
      controller.updateCursor(allNodesCursor);
    }
  }
}
