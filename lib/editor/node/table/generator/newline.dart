import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../../shortcuts/newline.dart';
import '../../basic.dart';
import '../table.dart';
import 'common.dart';

NodeWithPosition newlineWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  return operateWhileEditing(
      data, node, (c) => NewlineAction(c).invoke(NewlineIntent()));
}

NodeWithPosition newlineWhileSelecting(
    SelectingData<TablePosition> data, TableNode node) {
  final left = data.left;
  final right = data.right;
  if (left.inSameCell(right)) {
    final cell = node.getCellByPosition(left);
    if (!cell.wholeSelected(left.cellPosition, right.cellPosition)) {
      final sameIndex = left.index == right.index;
      BasicCursor cursor = sameIndex
          ? SelectingNodeCursor(left.index, left.position, right.position)
          : SelectingNodesCursor(IndexWithPosition(left.index, left.position),
          IndexWithPosition(right.index, right.position));
      var newCell = cell;
      final context = cell.buildContext(
          cursor: cursor,
          listeners: data.listeners,
          onReplace: (v) {
            newCell = cell.replaceMore(v.begin, v.end, v.newNodes);
            cursor = v.cursor;
          },
          onUpdate: (v) {
            newCell = cell.update(v.index, (n) => v.node);
            cursor = v.cursor;
          },
          onCursor: (c) {
            cursor = c;
          });
      NewlineAction(context).invoke(NewlineIntent());
      return NodeWithPosition(
          node.updateCell(left.row, left.column, (t) => newCell),
          left.fromCursor(cursor));
    }
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'newlineWhileSelecting', data.position);
}
