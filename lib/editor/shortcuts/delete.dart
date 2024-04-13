import 'package:flutter/material.dart';

import '../command/modify.dart';
import '../command/replace.dart';
import '../command/selecting_nodes/delete.dart';
import '../core/context.dart';
import '../core/controller.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import '../node/basic_node.dart';
import '../node/position_data.dart';

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class DeleteAction extends ContextAction<DeleteIntent> {
  final EditorContext editorContext;

  DeleteAction(this.editorContext);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = editorContext.cursor;
    final controller = editorContext.controller;
    if (cursor is EditingCursor) {
      final index = cursor.index;
      final node = controller.getNode(index);
      try {
        final r = node.onEdit(EditingData(cursor.position, EventType.delete));
        editorContext.execute(ModifyNode(r.position.toCursor(index), r.node));
      } on DeleteRequiresNewLineException catch (e) {
        logger.e('$runtimeType, $e');
        if (index == 0) return;
        final lastNode = controller.getNode(index - 1);
        try {
          final newNode = lastNode.merge(node);
          editorContext.execute(ReplaceNode(Replace(index - 1, index + 1,
              [newNode], EditingCursor(index - 1, lastNode.endPosition))));
        } on UnableToMergeException catch (e) {
          logger.e('$runtimeType, $e');
          editorContext.execute(ModifyNode(
              SelectingNodeCursor(
                  index - 1, lastNode.beginPosition, lastNode.endPosition),
              node));
        }
      } on DeleteToChangeNodeException catch(e){
        editorContext.execute(ReplaceNode(Replace(index, index + 1,
            [e.node], EditingCursor(index, e.position))));
      }
    } else if (cursor is SelectingNodeCursor) {
      final r = controller.getNode(cursor.index).onSelect(SelectingData(
          SelectingPosition(cursor.begin, cursor.end), EventType.delete));
      editorContext
          .execute(ModifyNode(r.position.toCursor(cursor.index), r.node));
    } else if (cursor is SelectingNodesCursor) {
      editorContext.execute(DeletionWhileSelectingNodes(cursor));
    }
  }
}
