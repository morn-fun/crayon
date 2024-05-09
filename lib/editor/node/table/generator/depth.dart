import '../../../core/context.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../../shortcuts/tab.dart';
import '../../basic.dart';
import '../table.dart';
import 'common.dart';

NodeWithPosition increaseDepthWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  return operateWhileEditing(
      data, node, (c) => TabAction(c).invoke(TabIntent()));
}

NodeWithPosition decreaseDepthWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  return operateWhileEditing(
      data, node, (c) => ShiftTabAction(c).invoke(ShiftTabIntent()));
}

NodeWithPosition increaseDepthWhileSelecting(
    SelectingData<TablePosition> data, TableNode node) {
  final left = data.left;
  final right = data.right;
  int lastDepth = data.extras is int ? data.extras : 0;
  int depth = node.depth;
  if (left == node.beginPosition && right == node.endPosition) {
    if (lastDepth < depth) {
      throw DepthNotAbleToIncreaseException(node.runtimeType, depth);
    }
    return NodeWithPosition(node.newNode(depth: depth + 1), data.position);
  }
  if (left.inSameCell(right)) {
    final cell = node.getCellByPosition(left);
    if (!cell.wholeSelected(left.cellPosition, right.cellPosition)) {
      final context = data.context
          .getChildContext(cell.getId(node.id, left.row, left.column))!;
      final sameIndex = left.index == right.index;

      BasicCursor cursor = sameIndex
          ? SelectingNodeCursor(left.index, left.position, right.position)
          : SelectingNodesCursor(IndexWithPosition(left.index, left.position),
              IndexWithPosition(right.index, right.position));
      TabAction(ActionContext(context, () => cursor)).invoke(TabIntent());
      throw NodeUnsupportedException(
          node.runtimeType, 'operateWhileEditing', null);
    }
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'increaseDepthWhileSelecting', data.position);
}

NodeWithPosition decreaseDepthWhileSelecting(
    SelectingData<TablePosition> data, TableNode node) {
  final left = data.left;
  final right = data.right;
  int lastDepth = data.extras is int ? data.extras : 0;
  int depth = node.depth;
  if (left == node.beginPosition && right == node.endPosition) {
    if (lastDepth < depth) {
      throw DepthNotAbleToIncreaseException(node.runtimeType, depth);
    }
    return NodeWithPosition(node.newNode(depth: depth + 1), data.position);
  }
  if (left.inSameCell(right)) {
    final cell = node.getCellByPosition(left);
    if (!cell.wholeSelected(left.cellPosition, right.cellPosition)) {
      final context = data.context
          .getChildContext(cell.getId(node.id, left.row, left.column))!;
      final sameIndex = left.index == right.index;

      BasicCursor cursor = sameIndex
          ? SelectingNodeCursor(left.index, left.position, right.position)
          : SelectingNodesCursor(IndexWithPosition(left.index, left.position),
              IndexWithPosition(right.index, right.position));
      ShiftTabAction(ActionContext(context,() =>  cursor)).invoke(ShiftTabIntent());
      throw NodeUnsupportedException(
          node.runtimeType, 'operateWhileEditing', null);
    }
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'decreaseDepthWhileSelecting', data.position);
}
