import 'package:pre_editor/editor/core/controller.dart';
import 'package:pre_editor/editor/cursor/rich_text_cursor.dart';

import '../core/command_invoker.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import '../node/rich_text_node/rich_text_node.dart';
import 'basic_command.dart';
import 'package:pre_editor/editor/node/basic_node.dart';

class DeleteWhileEditing implements BasicCommand {
  final EditingCursor cursor;

  DeleteWhileEditing(this.cursor);

  final _tag = 'DeleteWhileEditing';

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    final index = cursor.index;
    final node = controller.getNode(index);
    try {
      final newNodeWithPosition = node.delete(cursor.position);
      if (newNodeWithPosition == null) {
        final newNodes = [];
        if (index == 0) newNodes.add(RichTextNode.empty());
        final newCursor = index <= 0
            ? EditingCursor(0, RichTextNodePosition.empty())
            : EditingCursor(
                index - 1, controller.getNode(index - 1).endPosition);
        return controller.replace(Replace(index, index + 1, [], newCursor));
      } else {
        return controller.update(UpdateOne(index, newNodeWithPosition.node,
            EditingCursor(index, newNodeWithPosition.position)));
      }
    } on DeleteRequiresNewLineException catch (e) {
      logger.e('$_tag, $e');
      if (index == 0) return null;
      final lastNode = controller.getNode(index - 1);
      try {
        final newNode = lastNode.merge(node);
        return controller.replace(Replace(index - 1, index + 1, [newNode],
            EditingCursor(index - 1, lastNode.endPosition)));
      } on UnableToMergeException catch (e) {
        logger.e('$_tag, $e');
        return controller.update(UpdateOne(
            index,
            node,
            SelectingNodeCursor(
                index - 1, lastNode.beginPosition, lastNode.endPosition)));
      }
    } on DeleteNotAllowedException catch (e) {
      logger.e('$_tag, $e');
    }
    return null;
  }
}

class DeletionWhileSelectingNode implements BasicCommand {
  final SelectingNodeCursor cursor;

  DeletionWhileSelectingNode(this.cursor);

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    final index = cursor.index;
    final node = controller.getNode(index);
    final newLeft = node.frontPartNode(cursor.left);
    final newRight = node.rearPartNode(cursor.right);
    final newNode = newLeft.merge(newRight);
    return controller.update(
        UpdateOne(index, newNode, EditingCursor(index, newLeft.endPosition)));
  }
}

class DeletionWhileSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;

  DeletionWhileSelectingNodes(this.cursor);

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    final leftCursor = cursor.left;
    final rightCursor = cursor.right;
    final leftNode = controller.getNode(leftCursor.index);
    final rightNode = controller.getNode(rightCursor.index);
    final left = leftNode.frontPartNode(leftCursor.position);
    final right = rightNode.rearPartNode(rightCursor.position,
        newId: '${DateTime.now().millisecondsSinceEpoch}');
    try {
      final newNode = left.merge(right);
      return controller.replace(Replace(leftCursor.index, rightCursor.index + 1,
          [newNode], EditingCursor(leftCursor.index, left.endPosition)));
    } on UnableToMergeException catch (e) {
      logger.e('$runtimeType error: $e');
      return controller.replace(Replace(leftCursor.index, rightCursor.index + 1,
          [left, right], EditingCursor(leftCursor.index, left.endPosition)));
    }
  }
}
