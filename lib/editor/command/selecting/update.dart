import '../../core/command_invoker.dart';
import '../../core/editor_controller.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import '../../node/basic.dart';
import '../../cursor/node_position.dart';
import '../basic.dart';

class UpdateSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;
  final EventType type;
  final dynamic extra;

  UpdateSelectingNodes(this.cursor, this.type, {this.extra});

  @override
  UpdateControllerOperation? run(RichEditorController controller) {
    final left = cursor.left;
    final right = cursor.right;
    List<EditorNode> nodes = [];
    int i = left.index;
    late SingleNodePosition leftPosition;
    late SingleNodePosition rightPosition;
    while (i <= right.index) {
      final node = controller.getNode(i);
      NodeWithPosition np;
      if (i == left.index) {
        np = node.onSelect(SelectingData(
            SelectingPosition(left.position, node.endPosition), type,
            extras: extra));
        leftPosition = np.position;
      } else if (i == right.index) {
        np = node.onSelect(SelectingData(
            SelectingPosition(node.beginPosition, right.position), type,
            extras: extra));
        rightPosition = np.position;
      } else {
        np = node.onSelect(SelectingData(
            SelectingPosition(node.beginPosition, node.endPosition), type,
            extras: extra));
      }
      nodes.add(np.node);
      i++;
    }
    final newCursor = SelectingNodesCursor(
        IndexWithPosition(
            left.index, _getBySingleNodePosition(leftPosition, true)),
        IndexWithPosition(
            right.index, _getBySingleNodePosition(rightPosition, false)));
    return controller
        .replace(Replace(left.index, right.index + 1, nodes, newCursor));
  }

  NodePosition _getBySingleNodePosition(SingleNodePosition p, bool isLeft) {
    if (p is EditingPosition) {
      return p.position;
    } else if (p is SelectingPosition) {
      return isLeft ? p.left : p.right;
    }
    throw NodePositionInvalidException('do not match for 【$p】');
  }
}
