import 'package:crayon/editor/cursor/basic.dart';

import '../../../command/selecting/replacement.dart';
import '../../../core/copier.dart';
import '../../../cursor/node_position.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../table.dart';

NodeWithPosition typingWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  final p = data.position;
  final cell = node.getCellByPosition(p);
  final index = p.index;
  final innerNode = cell.getNode(index);
  late NodeWithPosition nodeWithPosition;
  try {
    nodeWithPosition = innerNode.onEdit(EditingData(
        p.position, EventType.typing, data.listeners,
        extras: data.extras));
  } on TypingToChangeNodeException catch (e) {
    nodeWithPosition = e.current;
  } on TypingRequiredOptionalMenuException catch (e) {
    nodeWithPosition = e.nodeWithPosition;

    ///TODO:show option menu here!
  }
  return NodeWithPosition(
      node.updateCell(
          p.row, p.column, to(cell.update(index, to(nodeWithPosition.node)))),
      p.fromCursor(nodeWithPosition.position.toCursor(index)));
}

NodeWithPosition typingWhileSelecting(
    SelectingData<TablePosition> data, TableNode node) {
  final left = data.left;
  final right = data.right;
  if (left.inSameCell(right)) {
    final cell = node.getCellByPosition(left);
    if (!cell.wholeSelected(left.cellPosition, right.cellPosition)) {
      final sameIndex = left.index == right.index;
      if (sameIndex) {
        final index = left.index;
        final innerNode = cell.getNode(index);
        late NodeWithPosition nodeWithPosition;
        try {
          nodeWithPosition = innerNode.onSelect(SelectingData(
              SelectingPosition(left.position, right.position),
              EventType.typing,
              data.listeners,
              extras: data.extras));
        } on TypingToChangeNodeException catch (e) {
          nodeWithPosition = e.current;
        } on TypingRequiredOptionalMenuException catch (e) {
          nodeWithPosition = e.nodeWithPosition;

          ///TODO:show option menu here!
        }
        return NodeWithPosition(
            node.updateCell(left.row, left.column,
                to(cell.update(index, to(nodeWithPosition.node)))),
            left.fromCursor(nodeWithPosition.position.toCursor(index)));
      }
      final listeners = data.listeners;
      BasicCursor cursor = SelectingNodesCursor(
          IndexWithPosition(left.index, left.position),
          IndexWithPosition(right.index, right.position));
      var newCell = cell;
      final context = cell.buildContext(
          cursor: cursor,
          listeners: listeners,
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
      context.execute(ReplaceSelectingNodes(
          cursor as SelectingNodesCursor, EventType.typing, data.extras));
      return NodeWithPosition(
          node.updateCell(left.row, left.column, to(newCell)),
          left.fromCursor(cursor));
    }
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'increaseDepthWhileSelecting', data.position);
}
