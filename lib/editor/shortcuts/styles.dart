import 'package:flutter/material.dart';

import '../command/selecting_nodes/update.dart';
import '../core/context.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';

class BoldIntent extends Intent {
  const BoldIntent();
}

class BoldAction extends ContextAction<BoldIntent> {
  final EditorContext editorContext;

  BoldAction(this.editorContext);

  @override
  void invoke(BoldIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final c = editorContext.cursor;
    if (c is SingleNodeCursor) {
      editorContext.onNodeEditing(c, EventType.bold);
    } else if (c is SelectingNodesCursor) {
      editorContext.execute(UpdateSelectingNodes(c, EventType.bold));
    }
  }
}
