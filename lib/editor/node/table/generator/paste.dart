import '../../../core/context.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../../shortcuts/copy_paste.dart';
import '../../basic.dart';
import '../table.dart';
import 'common.dart';

NodeWithCursor pasteWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  return operateWhileEditing(
      data, node, (c) => PasteAction(c).invoke(PasteIntent()));
}

NodeWithCursor pasteWhileSelecting(
    SelectingData<TablePosition> data, TableNode node) {
  final left = data.left;
  final right = data.right;
  if (left.sameCell(right)) {
    final cell = node.getCell(left.cellPosition);
    BasicCursor cursor = buildTableCellCursor(cell, left.cursor, right.cursor);
    final context = buildTableCellNodeContext(
        data.operator, left.cellPosition, node, cursor, data.index);
    PasteAction(ActionOperator(context)).invoke(PasteIntent());
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'pasteWhileSelecting', data.cursor);
}
