import '../../../editor/extension/node_context.dart';

import '../../core/command_invoker.dart';
import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../cursor/basic.dart';
import '../../node/basic.dart';
import '../basic.dart';

class InsertNewLineWhileSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;

  InsertNewLineWhileSelectingNodes(this.cursor);

  @override
  UpdateControllerOperation? run(NodesOperator nodeContext) {
    final leftCursor = cursor.left;
    final rightCursor = cursor.right;
    final leftNode = nodeContext.getNode(leftCursor.index);
    final rightNode = nodeContext.getNode(rightCursor.index);
    final left = leftNode.frontPartNode(leftCursor.position);
    var right =
        rightNode.rearPartNode(rightCursor.position, newId: randomNodeId);
    if (right.depth > left.depth + 1) {
      right = right.newNode(depth: left.depth + 1);
    }
    List<EditorNode> listNeedRefreshDepth =
        nodeContext.listNeedRefreshDepth(rightCursor.index, right.depth);
    return nodeContext.replace(Replace(
        leftCursor.index,
        rightCursor.index + 1 + listNeedRefreshDepth.length,
        [left, right, ...listNeedRefreshDepth],
        EditingCursor(leftCursor.index + listNeedRefreshDepth.length + 1,
            right.beginPosition)));
  }
}
