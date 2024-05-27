import '../../../editor/extension/node_context.dart';

import '../../core/command_invoker.dart';
import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import '../../node/basic.dart';
import '../basic.dart';

class DeletionWhileSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;

  DeletionWhileSelectingNodes(this.cursor);

  @override
  UpdateControllerOperation? run(NodesOperator operator) {
    final leftCursor = cursor.left;
    final rightCursor = cursor.right;
    final leftNode = operator.getNode(leftCursor.index);
    final rightNode = operator.getNode(rightCursor.index);
    final left = leftNode.frontPartNode(leftCursor.position);
    final right =
        rightNode.rearPartNode(rightCursor.position, newId: randomNodeId);
    try {
      final newNode = left.merge(right);
      List<EditorNode> listNeedRefreshDepth =
          operator.listNeedRefreshDepth(rightCursor.index, newNode.depth);
      return operator.replace(Replace(
          leftCursor.index,
          rightCursor.index + 1 + listNeedRefreshDepth.length,
          [newNode, ...listNeedRefreshDepth],
          EditingCursor(leftCursor.index, left.endPosition)));
    } on UnableToMergeException catch (e) {
      logger.e('$runtimeType error: $e');
      List<EditorNode> listNeedRefreshDepth =
          operator.listNeedRefreshDepth(rightCursor.index, right.depth);
      return operator.replace(Replace(
          leftCursor.index,
          rightCursor.index + 1 + listNeedRefreshDepth.length,
          [left, right, ...listNeedRefreshDepth],
          EditingCursor(leftCursor.index, left.endPosition)));
    }
  }
}
