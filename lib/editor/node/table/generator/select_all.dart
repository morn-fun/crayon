import '../../../core/copier.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/node_position.dart';
import '../../../cursor/table.dart';
import '../../../shortcuts/select_all.dart';
import '../../basic.dart';
import '../table.dart';
import 'common.dart';

NodeWithPosition selectAllWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  return operateWhileEditing(
      data, node, (c) => SelectAllAction(c).invoke(SelectAllIntent()));
}

NodeWithPosition selectAllWhileSelecting(
    SelectingData<TablePosition> data, TableNode node) {
  final left = data.left;
  final right = data.right;
  if (left.sameCell(right)) {
    final cell = node.getCell(left.cellPosition);
    final sameIndex = left.index == right.index;
    BasicCursor cursor = sameIndex
        ? SelectingNodeCursor(left.index, left.position, right.position)
        : SelectingNodesCursor(left.cursor, right.cursor);
    if (!cell.wholeSelected(cursor)) {
      if (sameIndex) {
        final innerNode = cell.getNode(left.index);
        if (left.position != innerNode.beginPosition ||
            right.position != innerNode.endPosition) {
          return NodeWithPosition(
            node,
            SelectingPosition(
              left.copy(
                  cursor: (c) =>
                      EditingCursor(c.index, innerNode.beginPosition)),
              right.copy(
                  cursor: (c) => EditingCursor(c.index, innerNode.endPosition)),
            ),
          );
        }
      }
      return NodeWithPosition(
        node,
        SelectingPosition(left.copy(cursor: to(cell.beginCursor)),
            right.copy(cursor: to(cell.endCursor))),
      );
    }
  }
  return NodeWithPosition(
      node, SelectingPosition(node.beginPosition, node.endPosition));
}
