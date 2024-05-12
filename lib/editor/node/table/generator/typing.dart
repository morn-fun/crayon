import '../../../command/selecting/replacement.dart';
import '../../../core/copier.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/node_position.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../../exception/menu.dart';
import '../../basic.dart';
import '../table.dart';

NodeWithPosition typingWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  final p = data.position;
  final cell = node.getCell(p.cellPosition);
  final index = p.index;
  final innerNode = cell.getNode(index);
  late NodeWithPosition nodeWithPosition;
  try {
    nodeWithPosition = innerNode.onEdit(EditingData(
        p.position, EventType.typing, data.context.getChildContext(cell.id)!,
        extras: data.extras));
  } on TypingToChangeNodeException catch (e) {
    nodeWithPosition = e.current;
  } on TypingRequiredOptionalMenuException catch (e) {
    nodeWithPosition = e.nodeWithPosition;
    throw TypingRequiredOptionalMenuException(
        NodeWithPosition(
            node.updateCell(p.row, p.column,
                to(cell.update(index, to(nodeWithPosition.node)))),
            p.cursorToPosition(nodeWithPosition.position.toCursor(index))),
        e.context);
  }
  return NodeWithPosition(
      node.updateCell(
          p.row, p.column, to(cell.update(index, to(nodeWithPosition.node)))),
      p.cursorToPosition(nodeWithPosition.position.toCursor(index)));
}

NodeWithPosition typingWhileSelecting(
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
        late NodeWithPosition nodeWithPosition;
        try {
          nodeWithPosition = innerNode.onSelect(SelectingData(
              SelectingPosition(left.position, right.position),
              EventType.typing,
              data.context.getChildContext(cell.id)!,
              extras: data.extras));
        } on TypingToChangeNodeException catch (e) {
          nodeWithPosition = e.current;
        } on TypingRequiredOptionalMenuException catch (e) {
          nodeWithPosition = e.nodeWithPosition;
          throw TypingRequiredOptionalMenuException(
              NodeWithPosition(
                  node.updateCell(left.row, left.column,
                      to(cell.update(index, to(nodeWithPosition.node)))),
                  left.cursorToPosition(
                      nodeWithPosition.position.toCursor(index))),
              e.context);
        }
        return NodeWithPosition(
            node.updateCell(left.row, left.column,
                to(cell.update(index, to(nodeWithPosition.node)))),
            left.cursorToPosition(nodeWithPosition.position.toCursor(index)));
      }
      BasicCursor cursor = SelectingNodesCursor(
          EditingCursor(left.index, left.position),
          EditingCursor(right.index, right.position));
      final context = data.context.getChildContext(cell.id)!;
      context.execute(ReplaceSelectingNodes(
          cursor as SelectingNodesCursor, EventType.typing, data.extras));
      throw NodeUnsupportedException(
          node.runtimeType, 'operateWhileEditing', null);
    }
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'increaseDepthWhileSelecting', data.position);
}
