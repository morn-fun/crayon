import '../../core/command_invoker.dart';
import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import '../../node/basic.dart';
import '../basic.dart';

class PasteWhileSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;
  final List<EditorNode> nodes;

  PasteWhileSelectingNodes(this.cursor, this.nodes);

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
      try {
        final r = newNode.onEdit(EditingData(
            EditingCursor(leftCursor.index, left.endPosition),
            EventType.paste,
            operator,
            extras: nodes));
        return operator.onOperation(Replace(
            leftCursor.index, rightCursor.index + 1, [r.node], r.cursor));
      } on PasteToCreateMoreNodesException catch (e) {
        return operator.onOperation(Replace(
            leftCursor.index,
            rightCursor.index + 1,
            e.nodes,
            EditingCursor(leftCursor.index + e.nodes.length - 1, e.position)));
      }
    } on UnableToMergeException catch (e) {
      logger.e('$runtimeType error: $e');
      final newNodes = List.of(nodes);
      newNodes.insert(0, left);
      newNodes.add(right);
      return operator.onOperation(Replace(
          leftCursor.index,
          rightCursor.index + 1,
          newNodes,
          EditingCursor(
              leftCursor.index + newNodes.length - 1, right.beginPosition)));
    }
  }
}
