import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/logger.dart';
import '../exception/command_exception.dart';


class RedoIntent extends Intent {
  const RedoIntent();
}

class RedoAction extends ContextAction<RedoIntent> {
  final EditorContext editorContext;

  RedoAction(this.editorContext);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      editorContext.redo();
    } on NoCommandException catch (e){
      logger.e('$e');
    } on PerformCommandException catch (e){
      logger.e('redo error: $e');
    }
  }
}
