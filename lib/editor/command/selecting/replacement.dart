import '../../core/command_invoker.dart';
import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import '../../node/basic.dart';
import '../basic.dart';

class ReplaceSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;
  final EventType type;
  final dynamic extra;

  ReplaceSelectingNodes(this.cursor, this.type, this.extra);

  @override
  UpdateControllerOperation? run(NodesOperator operator) {
    final left = cursor.left;
    final right = cursor.right;
    final leftNode = operator.getNode(left.index);
    final rightNode = operator.getNode(right.index);
    final newLeftNP = leftNode.onSelect(SelectingData(
        SelectingNodeCursor(left.index, left.position, leftNode.endPosition),
        type,
        operator,
        extras: extra));
    final newRight =
        rightNode.rearPartNode(right.position, newId: randomNodeId);
    final newCursor = newLeftNP.cursor;
    try {
      final newNode = newLeftNP.node.merge(newRight);
      return operator
          .onOperation(Replace(left.index, right.index + 1, [newNode], newCursor));
    } on UnableToMergeException catch (e) {
      logger.e('$runtimeType error: $e');
      return operator.onOperation(Replace(
          left.index, right.index + 1, [newLeftNP.node, newRight], newCursor));
    }
  }
}
