import 'package:flutter/material.dart';

import '../command/insertion.dart';
import '../core/context.dart';
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
    if (editorContext.typing) {
      editorContext.restartInput();
      return;
    }
    try {
      final cursor = editorContext.cursor;
      if (cursor is EditingCursor) {
        editorContext.execute(InsertNewline(cursor));
      }
    } on PerformCommandException catch (e) {
      logger.e('NewlineAction error: $e');
    }
  }
}
