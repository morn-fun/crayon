import '../../core/command_invoker.dart';
import '../../core/controller.dart';
import '../../core/logger.dart';
import '../../cursor/basic_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../node/basic_node.dart';
import '../basic_command.dart';

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
    final right =
        rightNode.rearPartNode(rightCursor.position, newId: randomNodeId);
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
