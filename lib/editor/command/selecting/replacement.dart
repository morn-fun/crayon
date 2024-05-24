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
  UpdateControllerOperation? run(NodesOperator nodeContext) {
    final left = cursor.left;
    final right = cursor.right;
    final leftNode = nodeContext.getNode(left.index);
    final rightNode = nodeContext.getNode(right.index);
    final newLeftNP = leftNode.onSelect(SelectingData(
        SelectingNodeCursor(left.index, left.position, leftNode.endPosition),
        type,
        nodeContext,
        extras: extra));
    final newRight =
        rightNode.rearPartNode(right.position, newId: randomNodeId);
    final newCursor = newLeftNP.cursor;
    try {
      final newNode = newLeftNP.node.merge(newRight);
      return nodeContext
          .replace(Replace(left.index, right.index + 1, [newNode], newCursor));
    } on UnableToMergeException catch (e) {
      logger.e('$runtimeType error: $e');
      return nodeContext.replace(Replace(
          left.index, right.index + 1, [newLeftNP.node, newRight], newCursor));
    }
  }
}
