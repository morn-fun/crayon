import '../../core/command_invoker.dart';
import '../../core/controller.dart';
import '../../cursor/basic_cursor.dart';
import '../../node/basic_node.dart';
import '../basic_command.dart';

class InsertNewLineWhileSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;

  InsertNewLineWhileSelectingNodes(this.cursor);

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    final leftCursor = cursor.left;
    final rightCursor = cursor.right;
    final leftNode = controller.getNode(leftCursor.index);
    final rightNode = controller.getNode(rightCursor.index);
    final left = leftNode.frontPartNode(leftCursor.position);
    var right =
        rightNode.rearPartNode(rightCursor.position, newId: randomNodeId);
    if (right.depth > left.depth + 1) {
      right = right.newNode(depth: left.depth + 1);
    }
    List<EditorNode> listNeedRefreshDepth =
        controller.listNeedRefreshDepth(rightCursor.index, right.depth);
    return controller.replace(Replace(
        leftCursor.index,
        rightCursor.index + 1 + listNeedRefreshDepth.length,
        [left, right, ...listNeedRefreshDepth],
        EditingCursor(leftCursor.index + listNeedRefreshDepth.length + 1,
            right.beginPosition)));
  }
}
