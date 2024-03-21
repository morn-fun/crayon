import 'package:flutter/material.dart';

import '../command/deletion.dart';
import '../core/context.dart';
import '../core/events.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../exception/command_exception.dart';

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class DeleteAction extends ContextAction<DeleteIntent> {
  final EditorContext editorContext;

  DeleteAction(this.editorContext);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      final cursor = editorContext.cursor;
      final controller = editorContext.controller;
      if (cursor is EditingCursor) {
        editorContext.handleEventWhileEditing(
            EditingEvent(cursor, EventType.delete, ''));
      } else if (cursor is SelectingNodeCursor) {
        editorContext.execute(DeletionWhileSelectingNode(cursor));
      } else if (cursor is SelectingNodesCursor) {
        editorContext.execute(DeletionWhileSelectingNodes(cursor));
      }
    } on PerformCommandException catch (e) {
      logger.e('$runtimeType error: $e');
    }
  }
}
