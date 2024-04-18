import '../../../editor/extension/int_extension.dart';
import '../../../editor/node/position_data.dart';

import '../../core/command_invoker.dart';
import '../../core/editor_controller.dart';
import '../../cursor/basic_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../node/basic_node.dart';
import '../basic_command.dart';

class IncreaseNodesDepth implements BasicCommand {
  final SelectingNodesCursor cursor;

  IncreaseNodesDepth(this.cursor);

  @override
  UpdateControllerOperation? run(RichEditorController controller) {
    final leftCursor = cursor.left;
    final rightCursor = cursor.right;
    int lastIndex = leftCursor.index;
    int lastDepth = lastIndex > 0 ? controller.getNode(lastIndex - 1).depth : 0;
    final leftNode = controller.getNode(leftCursor.index);
    int depth = leftNode.depth;
    if (lastDepth < depth) {
      throw DepthNotAbleToIncreaseException(leftNode.runtimeType, depth);
    }
    int l = leftCursor.index;
    final r = rightCursor.index;
    final newNodes = <EditorNode>[];
    while (l <= r) {
      final node = controller.getNode(l);
      newNodes.add(node.newNode(depth: node.depth + 1));
      l++;
    }
    return controller.replace(Replace(leftCursor.index,
        leftCursor.index + newNodes.length, newNodes, cursor));
  }
}

class DecreaseNodesDepth implements BasicCommand {
  final SelectingNodesCursor cursor;

  DecreaseNodesDepth(this.cursor);

  @override
  UpdateControllerOperation? run(RichEditorController controller) {
    final leftCursor = cursor.left;
    final rightCursor = cursor.right;
    int l = leftCursor.index;
    final r = rightCursor.index;
    final newNodes = <EditorNode>[];
    while (l < r) {
      final node = controller.getNode(l);
      final newNode =
          node.depth > 0 ? node.newNode(depth: node.depth.decrease()) : node;
      newNodes.add(newNode);
      l++;
    }

    final lastNode = controller.getNode(r);
    try {
      final nodePosition = lastNode.onSelect(SelectingData(
          SelectingPosition(lastNode.beginPosition, rightCursor.position),
          EventType.decreaseDepth));
      newNodes.add(nodePosition.node);
    } on DepthNeedDecreaseMoreException catch (e) {
      newNodes.add(lastNode.newNode(depth: lastNode.depth.decrease()));
      int index = r + 1;
      while (index < controller.nodeLength) {
        final n = controller.getNode(index);
        if (n.depth - e.depth > 1) {
          newNodes.add(n.newNode(depth: n.depth.decrease()));
        } else {
          break;
        }
        index++;
      }
    }
    return controller.replace(Replace(leftCursor.index,
        leftCursor.index + newNodes.length, newNodes, cursor));
  }
}
