import '../../../core/copier.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../shortcuts/select_all.dart';
import '../../basic.dart';
import '../table.dart';
import 'common.dart';

NodeWithCursor selectAllWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  return operateWhileEditing(
      data, node, (c) => SelectAllAction(c).invoke(SelectAllIntent()));
}

NodeWithCursor selectAllWhileSelecting(
    SelectingData<TablePosition> data, TableNode node) {
  final left = data.left;
  final right = data.right;
  if (left.sameCell(right)) {
    final cell = node.getCell(left.cellPosition);
    final sameIndex = left.index == right.index;
    BasicCursor cursor = buildTableCellCursor(cell, left.cursor, right.cursor);
    if (!cell.wholeSelected(cursor)) {
      if (sameIndex) {
        final innerNode = cell.getNode(left.index);
        if (left.position != innerNode.beginPosition ||
            right.position != innerNode.endPosition) {
          final ctx = buildTableCellNodeContext(
              data.operator, left.cellPosition, node, cursor, data.index);
          final r = innerNode.onSelect(SelectingData(
              SelectingNodeCursor(left.index, left.position, right.position),
              EventType.selectAll,
              ctx));
          final p = r.cursor;
          if (p is SelectingNodeCursor) {
            final rp = SelectingNodeCursor(
                data.index,
                left.copy(cursor: (c) => EditingCursor(c.index, p.begin)),
                left.copy(cursor: (c) => EditingCursor(c.index, p.end)));
            return NodeWithCursor(node, rp);
          }
        }
      }
      return NodeWithCursor(
        node,
        SelectingNodeCursor(data.index, left.copy(cursor: to(cell.beginCursor)),
            right.copy(cursor: to(cell.endCursor))),
      );
    }
  }
  return NodeWithCursor(node,
      SelectingNodeCursor(data.index, node.beginPosition, node.endPosition));
}
