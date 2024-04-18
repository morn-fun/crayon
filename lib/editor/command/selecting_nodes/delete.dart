import '../../../editor/extension/rich_editor_controller_extension.dart';

import '../../core/command_invoker.dart';
import '../../core/editor_controller.dart';
import '../../core/logger.dart';
import '../../cursor/basic_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../node/basic_node.dart';
import '../basic_command.dart';

class DeletionWhileSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;

  DeletionWhileSelectingNodes(this.cursor);

  @override
  UpdateControllerOperation? run(RichEditorController controller) {
    final leftCursor = cursor.left;
    final rightCursor = cursor.right;
    final leftNode = controller.getNode(leftCursor.index);
    final rightNode = controller.getNode(rightCursor.index);
    final left = leftNode.frontPartNode(leftCursor.position);
    final right =
        rightNode.rearPartNode(rightCursor.position, newId: randomNodeId);
    try {
      final newNode = left.merge(right);
      List<EditorNode> listNeedRefreshDepth =
          controller.listNeedRefreshDepth(rightCursor.index, newNode.depth);
      return controller.replace(Replace(
          leftCursor.index,
          rightCursor.index + 1 + listNeedRefreshDepth.length,
          [newNode, ...listNeedRefreshDepth],
          EditingCursor(leftCursor.index, left.endPosition)));
    } on UnableToMergeException catch (e) {
      logger.e('$runtimeType error: $e');
      List<EditorNode> listNeedRefreshDepth =
          controller.listNeedRefreshDepth(rightCursor.index, right.depth);
      return controller.replace(Replace(
          leftCursor.index,
          rightCursor.index + 1 + listNeedRefreshDepth.length,
          [left, right, ...listNeedRefreshDepth],
          EditingCursor(leftCursor.index, left.endPosition)));
    }
  }
}
