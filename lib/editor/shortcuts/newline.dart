import 'package:flutter/material.dart';

import '../command/selecting_nodes/newline.dart';
import '../core/context.dart';
import '../core/events.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../exception/command_exception.dart';

class NewlineIntent extends Intent {
  const NewlineIntent();
}

class NewlineAction extends ContextAction<NewlineIntent> {
  final EditorContext editorContext;

  NewlineAction(this.editorContext);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      final cursor = editorContext.cursor;
      if (cursor is EditingCursor) {
        editorContext
            .handleEventWhileEditing(EditingEvent(cursor, EventType.newline));
      } else if (cursor is SelectingNodeCursor) {
        editorContext.handleEventWhileSelectingNode(
            SelectingNodeEvent(cursor, EventType.newline));
      } else if (cursor is SelectingNodesCursor) {
        editorContext.execute(InsertNewLineWhileSelectingNodes(cursor));
      }
    } on PerformCommandException catch (e) {
      logger.e('NewlineAction error: $e');
    }
  }
}
