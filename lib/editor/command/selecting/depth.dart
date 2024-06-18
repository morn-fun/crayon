import '../../../editor/extension/node_context.dart';

import '../../../editor/extension/int.dart';
import '../../core/context.dart';

import '../../core/command_invoker.dart';
import '../../core/editor_controller.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import '../../node/basic.dart';
import '../basic.dart';

class IncreaseNodesDepth implements BasicCommand {
  final SelectingNodesCursor cursor;

  IncreaseNodesDepth(this.cursor);

  @override
  UpdateControllerOperation? run(NodesOperator operator) {
    final leftCursor = cursor.left;
    final rightCursor = cursor.right;
    int lastIndex = leftCursor.index;
    int lastDepth = lastIndex > 0 ? operator.getNode(lastIndex - 1).depth : 0;
    final leftNode = operator.getNode(leftCursor.index);
    int depth = leftNode.depth;
    if (lastDepth < depth) {
      throw NodeUnsupportedException(leftNode.runtimeType,
          'IncreaseNodesDepth with $lastDepth small than $depth', depth);
    }
    int l = leftCursor.index;
    final r = rightCursor.index;
    final newNodes = <EditorNode>[];
    while (l <= r) {
      final node = operator.getNode(l);
      newNodes.add(node.newNode(depth: node.depth + 1));
      l++;
    }
    return operator.onOperation(Replace(leftCursor.index,
        leftCursor.index + newNodes.length, newNodes, cursor));
  }
}

class DecreaseNodesDepth implements BasicCommand {
  final SelectingNodesCursor cursor;

  DecreaseNodesDepth(this.cursor);

  @override
  UpdateControllerOperation? run(NodesOperator operator) {
    final leftCursor = cursor.left;
    final rightCursor = cursor.right;
    int l = leftCursor.index;
    final r = rightCursor.index;
    final newNodes = <EditorNode>[];
    while (l < r) {
      final node = operator.getNode(l);
      final newNode =
          node.depth > 0 ? node.newNode(depth: node.depth.decrease()) : node;
      newNodes.add(newNode);
      l++;
    }

    final lastNode = operator.getNode(r);
    try {
      final nodePosition = lastNode.onSelect(SelectingData(
          SelectingNodeCursor(r, lastNode.beginPosition, rightCursor.position),
          EventType.decreaseDepth,
          operator));
      newNodes.add(nodePosition.node);
    } on DepthNeedDecreaseMoreException catch (e) {
      newNodes.add(lastNode.newNode(depth: lastNode.depth.decrease()));
      correctDepth(operator.nodeLength, (i) => operator.getNode(i), r + 1,
          e.depth, newNodes);
    }
    return operator.onOperation(Replace(leftCursor.index,
        leftCursor.index + newNodes.length, newNodes, cursor));
  }
}

void correctDepth(int maxLength, NodeGetter getter, int start, int depth,
    List<EditorNode> nodes,
    {bool limitChildren = true}) {
  int index = start;
  while (index < maxLength) {
    final n = getter.call(index);
    final different = limitChildren ? 0 : 1;
    if (n.depth - depth > different) {
      nodes.add(n.newNode(depth: n.depth.decrease()));
    } else {
      break;
    }
    index++;
  }
}
