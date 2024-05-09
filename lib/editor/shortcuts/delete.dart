import 'package:flutter/material.dart';

import '../command/modification.dart';
import '../command/replace.dart';
import '../command/selecting/deletion.dart';
import '../command/selecting/depth.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import '../core/logger.dart';
import '../cursor/basic.dart';
import '../exception/editor_node.dart';
import '../node/basic.dart';
import '../cursor/node_position.dart';

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class DeleteAction extends ContextAction<DeleteIntent> {
  final ActionContext ac;

  NodeContext get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  DeleteAction(this.ac);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = this.cursor;
    if (cursor is EditingCursor) {
      final index = cursor.index;
      final node = nodeContext.getNode(index);
      try {
        final r = node.onEdit(
            EditingData(cursor.position, EventType.delete, nodeContext));
        nodeContext.execute(ModifyNode(r.position.toCursor(index), r.node));
      } on DeleteRequiresNewLineException catch (e) {
        logger.e('$runtimeType, ${e.message}');
        if (index == 0) return;
        final lastNode = nodeContext.getNode(index - 1);
        try {
          final newNode = lastNode.merge(node);
          final newNodes = [newNode];
          correctDepth(nodeContext.nodeLength, (i) => nodeContext.getNode(i),
              index + 1, newNode.depth, newNodes,
              limitChildren: false);
          nodeContext.execute(ReplaceNode(Replace(
              index - 1,
              index + newNodes.length,
              newNodes,
              EditingCursor(index - 1, lastNode.endPosition))));
        } on UnableToMergeException catch (e) {
          logger.e('$runtimeType, ${e.message}');
          nodeContext.execute(ModifyNode(
              SelectingNodeCursor(
                  index - 1, lastNode.beginPosition, lastNode.endPosition),
              node));
        }
      } on DeleteToChangeNodeException catch (e) {
        logger.e('$runtimeType, ${e.message}');
        nodeContext.execute(ReplaceNode(Replace(
            index, index + 1, [e.node], EditingCursor(index, e.position))));
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    } else if (cursor is SelectingNodeCursor) {
      try {
        final r = nodeContext.getNode(cursor.index).onSelect(SelectingData(
            SelectingPosition(cursor.begin, cursor.end),
            EventType.delete,
            nodeContext));
        nodeContext
            .execute(ModifyNode(r.position.toCursor(cursor.index), r.node));
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    } else if (cursor is SelectingNodesCursor) {
      nodeContext.execute(DeletionWhileSelectingNodes(cursor));
    }
  }
}
