import '../../core/command_invoker.dart';
import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import '../../node/basic.dart';
import '../basic.dart';

class UpdateSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;
  final EventType type;
  final dynamic extra;

  UpdateSelectingNodes(this.cursor, this.type, {this.extra});

  @override
  UpdateControllerOperation? run(NodesOperator operator) {
    final left = cursor.left;
    final right = cursor.right;
    List<EditorNode> nodes = [];
    int i = left.index;
    SingleNodeCursor leftPosition = left;
    SingleNodeCursor rightPosition = right;
    while (i <= right.index) {
      final node = operator.getNode(i);
      try {
        NodeWithCursor nc;
        if (i == left.index) {
          nc = node.onSelect(SelectingData(
              SelectingNodeCursor(i, left.position, node.endPosition),
              type,
              operator,
              extras: extra));
          leftPosition = nc.cursor;
        } else if (i == right.index) {
          nc = node.onSelect(SelectingData(
              SelectingNodeCursor(i, node.beginPosition, right.position),
              type,
              operator,
              extras: extra));
          rightPosition = nc.cursor;
        } else {
          nc = node.onSelect(SelectingData(
              SelectingNodeCursor(i, node.beginPosition, node.endPosition),
              type,
              operator,
              extras: extra));
        }
        nodes.add(nc.node);
      } on NodeUnsupportedException catch(e){
        nodes.add(node);
        logger.e('UpdateSelectingNodes error:${e.message}');
      }
      i++;
    }
    final newCursor = SelectingNodesCursor(
        EditingCursor(left.index, _getBySingleNodePosition(leftPosition, true)),
        EditingCursor(
            right.index, _getBySingleNodePosition(rightPosition, false)));
    return operator
        .replace(Replace(left.index, right.index + 1, nodes, newCursor));
  }

  NodePosition _getBySingleNodePosition(SingleNodeCursor p, bool isLeft) {
    if (p is EditingCursor) {
      return p.position;
    } else if (p is SelectingNodeCursor) {
      return isLeft ? p.left : p.right;
    }
    throw NodePositionInvalidException('do not match for 【$p】');
  }
}
