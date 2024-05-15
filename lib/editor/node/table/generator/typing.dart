import '../../../command/selecting/replacement.dart';
import '../../../core/copier.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../../exception/menu.dart';
import '../../basic.dart';
import '../table.dart';
import 'common.dart';

NodeWithCursor typingWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  final p = data.position;
  final cell = node.getCell(p.cellPosition);
  final index = p.index;
  final innerNode = cell.getNode(index);
  late NodeWithCursor nodeWithCursor;
  final ctx = buildTableCellNodeContext(
      data.context, p.cellPosition, node, p.cursor, data.index);
  try {
    nodeWithCursor = innerNode.onEdit(
        EditingData(p.cursor, EventType.typing, ctx, extras: data.extras));
  } on TypingToChangeNodeException catch (e) {
    nodeWithCursor = e.current;
  } on TypingRequiredOptionalMenuException catch (e) {
    nodeWithCursor = e.nodeWithCursor;
    throw TypingRequiredOptionalMenuException(
        NodeWithCursor(
            node.updateCell(p.row, p.column,
                to(cell.update(index, to(nodeWithCursor.node)))),
            EditingCursor(
                data.index,
                TablePosition(
                    p.cellPosition, nodeWithCursor.cursor as EditingCursor))),
        e.context);
  }
  return NodeWithCursor(
      node.updateCell(
          p.row, p.column, to(cell.update(index, to(nodeWithCursor.node)))),
      EditingCursor(
          data.index,
          TablePosition(
              p.cellPosition, nodeWithCursor.cursor as EditingCursor)));
}

NodeWithCursor typingWhileSelecting(
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
        final index = left.index;
        final innerNode = cell.getNode(index);
        late NodeWithCursor nodeWithCursor;
        try {
          final c =
              SelectingNodeCursor(left.index, left.position, right.position);
          nodeWithCursor = innerNode.onSelect(SelectingData(
              c,
              EventType.typing,
              buildTableCellNodeContext(
                  data.context, left.cellPosition, node, c, data.index),
              extras: data.extras));
        } on TypingToChangeNodeException catch (e) {
          nodeWithCursor = e.current;
        } on TypingRequiredOptionalMenuException catch (e) {
          nodeWithCursor = e.nodeWithCursor;
          throw TypingRequiredOptionalMenuException(
              NodeWithCursor(
                  node.updateCell(left.row, left.column,
                      to(cell.update(index, to(nodeWithCursor.node)))),
                  EditingCursor(
                      data.index,
                      TablePosition(left.cellPosition,
                          nodeWithCursor.cursor as EditingCursor))),
              e.context);
        }
        return NodeWithCursor(
            node.updateCell(left.row, left.column,
                to(cell.update(index, to(nodeWithCursor.node)))),
            EditingCursor(
                data.index,
                TablePosition(left.cellPosition,
                    nodeWithCursor.cursor as EditingCursor)));
      }
      BasicCursor cursor = SelectingNodesCursor(
          EditingCursor(left.index, left.position),
          EditingCursor(right.index, right.position));
      final context = buildTableCellNodeContext(
          data.context, left.cellPosition, node, cursor, data.index);
      context.execute(ReplaceSelectingNodes(
          cursor as SelectingNodesCursor, EventType.typing, data.extras));
      throw NodeUnsupportedException(
          node.runtimeType, 'operateWhileEditing', null);
    }
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'increaseDepthWhileSelecting', data.cursor);
}
