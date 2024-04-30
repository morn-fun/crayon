import '../../../core/copier.dart';
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
  if (left.inSameCell(right)) {
    final cell = node.getCellByPosition(left);
    if (!cell.wholeSelected(left.cellPosition, right.cellPosition)) {
      final sameIndex = left.index == right.index;
      if (sameIndex) {
        final innerNode = cell.getNode(left.index);
        if (left.position != innerNode.beginPosition ||
            right.position != innerNode.endPosition) {
          return NodeWithPosition(
            node,
            SelectingPosition(
                left.copy(
                    position: (p) =>
                        p.copy(position: to(innerNode.beginPosition))),
                right.copy(
                    position: (p) =>
                        p.copy(position: to(innerNode.endPosition)))),
          );
        }
      }
      return NodeWithPosition(
        node,
        SelectingPosition(left.copy(position: to(cell.beginPosition)),
            right.copy(position: to(cell.endPosition))),
      );
    }
  }
  return NodeWithPosition(
      node, SelectingPosition(node.beginPosition, node.endPosition));
}
