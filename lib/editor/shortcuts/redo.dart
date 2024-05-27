import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/logger.dart';
import '../exception/command.dart';

class RedoIntent extends Intent {
  const RedoIntent();
}

class RedoAction extends ContextAction<RedoIntent> {
  final ActionOperator ac;

  EditorContext get editorContext => ac.operator as EditorContext;

  RedoAction(this.ac);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      editorContext.redo();
    } on NoCommandException catch (e) {
      logger.e('$e');
    } on PerformCommandException catch (e) {
      logger.e('redo error: $e');
    }
  }
}
