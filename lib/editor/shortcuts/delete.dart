import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/context.dart';
import '../core/logger.dart';

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class DeleteAction extends ContextAction<DeleteIntent> {
  final EditorContext editorContext;

  DeleteAction(this.editorContext);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    if (editorContext.typing) {

    }
  }
}
