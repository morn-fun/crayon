import 'package:flutter/material.dart';
import '../../editor/command/replace.dart';
import '../../editor/exception/editor_node.dart';

import '../command/selecting/newline.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import '../core/logger.dart';
import '../cursor/basic.dart';
import '../node/basic.dart';

class NewlineIntent extends Intent {
  const NewlineIntent();
}

class NewlineAction extends ContextAction<NewlineIntent> {
  final NodeContext nodeContext;

  NewlineAction(this.nodeContext);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final c = nodeContext.cursor;
    if (c is EditingCursor) {
      try {
        nodeContext.onNodeEditing(c, EventType.newline);
      } on NewlineRequiresNewNode catch (e) {
        logger.e('$runtimeType $e');
        int index = c.index;
        final current = nodeContext.getNode(index);
        final left = current.frontPartNode(c.position);
        final right = current.rearPartNode(c.position, newId: randomNodeId);
        nodeContext.execute(ReplaceNode(Replace(index, index + 1,
            [left, right], EditingCursor(index + 1, right.beginPosition))));
      } on NewlineRequiresNewSpecialNode catch (e) {
        int index = c.index;
        nodeContext.execute(ReplaceNode(Replace(index, index + 1, e.newNodes,
            EditingCursor(index + e.newNodes.length - 1, e.position))));
      }
    } else if (c is SelectingNodeCursor) {
      try {
        nodeContext.onNodeEditing(c, EventType.newline);
      } on NewlineRequiresNewNode catch (e) {
        logger.e('$runtimeType $e');
        int index = c.index;
        final current = nodeContext.getNode(index);
        final left = current.frontPartNode(c.left);
        final right = current.rearPartNode(c.right, newId: randomNodeId);
        nodeContext.execute(ReplaceNode(Replace(index, index + 1,
            [left, right], EditingCursor(index + 1, right.beginPosition))));
      } on NewlineRequiresNewSpecialNode catch (e) {
        int index = c.index;
        nodeContext.execute(ReplaceNode(Replace(index, index + 1, e.newNodes,
            EditingCursor(index + e.newNodes.length - 1, e.position))));
      }
    } else if (c is SelectingNodesCursor) {
      nodeContext.execute(InsertNewLineWhileSelectingNodes(c));
    }
  }
}
