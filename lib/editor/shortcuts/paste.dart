import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../command/modification.dart';
import '../command/replacement.dart';
import '../command/selecting_nodes/deletion.dart';
import '../core/context.dart';
import '../core/controller.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import '../node/basic_node.dart';
import '../node/position_data.dart';

class PasteIntent extends Intent {
  const PasteIntent();
}

class PasteAction extends ContextAction<PasteIntent> {
  final EditorContext editorContext;

  PasteAction(this.editorContext);

  @override
  void invoke(PasteIntent intent, [BuildContext? context]) async {
    logger.i('$runtimeType is invoking!');
    final Map<String, dynamic>? result = await SystemChannels.platform.invokeMethod(
      'Clipboard.getData',
      'nodes',
    );
    logger.i('$runtimeType, result [$result]');
    final cursor = editorContext.cursor;
    if (cursor is EditingCursor) {

    } else if (cursor is SelectingNodeCursor) {

    } else if (cursor is SelectingNodesCursor) {

    }
  }
}
