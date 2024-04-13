import 'package:flutter/material.dart';
import '../../editor/command/replace.dart';
import '../../editor/exception/editor_node_exception.dart';

import '../command/selecting_nodes/newline.dart';
import '../core/context.dart';
import '../core/controller.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';

class NewlineIntent extends Intent {
  const NewlineIntent();
}

class NewlineAction extends ContextAction<NewlineIntent> {
  final EditorContext editorContext;

  NewlineAction(this.editorContext);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final c = editorContext.cursor;
    final controller = editorContext.controller;
    if (c is EditingCursor) {
      try {
        editorContext.onNodeEditing(c, EventType.newline);
      } on NewlineRequiresNewNode catch (e) {
        logger.e('$runtimeType $e');
        int index = c.index;
        final current = controller.getNode(index);
        final left = current.frontPartNode(c.position);
        final right = current.rearPartNode(c.position, newId: randomNodeId);
        editorContext.execute(ReplaceNode(Replace(index, index + 1,
            [left, right], EditingCursor(index + 1, right.beginPosition))));
      } on NewlineRequiresNewSpecialNode catch (e) {
        int index = c.index;
        editorContext.execute(ReplaceNode(Replace(index, index + 1, e.newNodes,
            EditingCursor(index + e.newNodes.length - 1, e.position))));
      }
    } else if (c is SelectingNodeCursor) {
      try {
        editorContext.onNodeEditing(c, EventType.newline);
      } on NewlineRequiresNewNode catch (e) {
        logger.e('$runtimeType $e');
        int index = c.index;
        final current = controller.getNode(index);
        final left = current.frontPartNode(c.left);
        final right = current.rearPartNode(c.right, newId: randomNodeId);
        editorContext.execute(ReplaceNode(Replace(index, index + 1,
            [left, right], EditingCursor(index + 1, right.beginPosition))));
      } on NewlineRequiresNewSpecialNode catch (e) {
        int index = c.index;
        editorContext.execute(ReplaceNode(Replace(index, index + 1, e.newNodes,
            EditingCursor(index + e.newNodes.length - 1, e.position))));
      }
    } else if (c is SelectingNodesCursor) {
      editorContext.execute(InsertNewLineWhileSelectingNodes(c));
    }
  }
}
