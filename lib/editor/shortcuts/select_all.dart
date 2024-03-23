import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/events.dart';
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
      editorContext
          .handleEventWhileEditing(EditingEvent(cursor, EventType.selectAll));
    } else if (cursor is SelectingNodeCursor) {
      editorContext.handleEventWhileSelectingNode(
          SelectingNodeEvent(cursor, EventType.selectAll));
    } else if (cursor is SelectingNodesCursor) {
      final allNodesCursor = controller.selectAllCursor;
      if (cursor == allNodesCursor) return;
      controller.updateCursor(allNodesCursor);
    }
  }
}
