import '../../core/command_invoker.dart';
import '../../core/controller.dart';
import '../../core/logger.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../node/rich_text_node/rich_text_node.dart';
import '../basic_command.dart';

class DeleteWhileEditingRichTextNode implements BasicCommand {
  final EditingCursor<RichTextNodePosition> cursor;
  final RichTextNode node;

  DeleteWhileEditingRichTextNode(this.cursor, this.node);

  final _tag = 'DeleteWhileEditing';

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    final index = cursor.index;
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

class DeleteWhileSelectingRichTextNode implements BasicCommand{
  final SelectingNodeCursor<RichTextNodePosition> cursor;
  final RichTextNode node;

  DeleteWhileSelectingRichTextNode(this.cursor, this.node);

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