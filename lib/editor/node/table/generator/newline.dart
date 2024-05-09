import '../../../core/context.dart';
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
      final context = data.context
          .getChildContext(cell.getId(node.id, left.row, left.column))!;
      final sameIndex = left.index == right.index;
      BasicCursor cursor = sameIndex
          ? SelectingNodeCursor(left.index, left.position, right.position)
          : SelectingNodesCursor(IndexWithPosition(left.index, left.position),
              IndexWithPosition(right.index, right.position));
      NewlineAction(ActionContext(context,() =>  cursor)).invoke(NewlineIntent());
      throw NodeUnsupportedException(
          node.runtimeType, 'operateWhileEditing', null);
    }
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'newlineWhileSelecting', data.position);
}
