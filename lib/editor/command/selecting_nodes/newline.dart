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
    final right =
        rightNode.rearPartNode(rightCursor.position, newId: randomNodeId);
    return controller.replace(Replace(
        leftCursor.index,
        rightCursor.index + 1,
        [left, right],
        EditingCursor(leftCursor.index + 1, right.beginPosition)));
  }
}
