import '../../../core/context.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../../shortcuts/newline.dart';
import '../../basic.dart';
import '../table.dart';
import 'common.dart';

NodeWithCursor newlineWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  return operateWhileEditing(
      data, node, (c) => NewlineAction(c).invoke(NewlineIntent()));
}

NodeWithCursor newlineWhileSelecting(
    SelectingData<TablePosition> data, TableNode node) {
  final left = data.left;
  final right = data.right;
  if (left.sameCell(right)) {
    final cell = node.getCell(left.cellPosition);
    BasicCursor cursor = buildTableCellCursor(cell, left.cursor, right.cursor);
    if (!cell.wholeSelected(cursor)) {
      final context = buildTableCellNodeContext(
          data.context, left.cellPosition, node, cursor, data.index);
      NewlineAction(ActionContext(context, () => cursor))
          .invoke(NewlineIntent());
    }
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'newlineWhileSelecting', data.cursor);
}
