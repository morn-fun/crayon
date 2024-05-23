import '../../../../editor/cursor/basic.dart';
import '../../../core/context.dart';
import '../../../core/copier.dart';
import '../../../cursor/rich_text.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../../shortcuts/delete.dart';
import '../../basic.dart';
import '../../rich_text/rich_text.dart';
import '../table.dart';
import 'common.dart';

NodeWithCursor deleteWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  return operateWhileEditing(
      data, node, (c) => DeleteAction(c).invoke(DeleteIntent()));
}

NodeWithCursor deleteWhileSelecting(
    SelectingData<TablePosition> data, TableNode node) {
  final left = data.left;
  final right = data.right;
  final emptyTextNode = RichTextNode.from([]);
  final nodeBegin = node.beginPosition, nodeEnd = node.endPosition;
  if (left == nodeBegin && right == nodeEnd) {
    return NodeWithCursor(
        emptyTextNode, emptyTextNode.beginPosition.toCursor(data.index));
  }
  if (left.sameCell(right)) {
    final cell = node.getCell(left.cellPosition);
    final ctx = data.context;
    final sameIndex = left.index == right.index;
    BasicCursor cursor = sameIndex
        ? SelectingNodeCursor(left.index, left.position, right.position)
        : SelectingNodesCursor(EditingCursor(left.index, left.position),
            EditingCursor(right.index, right.position));
    if (cell.wholeSelected(cursor)) {
      final newNode = node.updateCell(left.row, left.column, (t) => t.clear());
      return NodeWithCursor(
          newNode,
          left
              .copy(cursor: to(newNode.getCell(left.cellPosition).beginCursor))
              .toCursor(data.index));
    }
    final context = buildTableCellNodeContext(
        ctx, left.cellPosition, node, cursor, data.index);
    DeleteAction(ActionContext(context, () => cursor)).invoke(DeleteIntent());
    throw NodeUnsupportedException(
        node.runtimeType, 'operateWhileEditing', null);
  }
  final newNode = node.updateMore(left.cellPosition, right.cellPosition, (t) {
    return t
        .map((e) => e.updateMore(0, e.length, (m) {
              return m.map((n) => n.copy(nodes: [])).toList();
            }, initNum: 0))
        .toList();
  });
  return NodeWithCursor(
      newNode,
      SelectingNodeCursor(
          data.index,
          left,
          right.copy(
              cursor: to(EditingCursor(0, RichTextNodePosition.zero())))));
}
