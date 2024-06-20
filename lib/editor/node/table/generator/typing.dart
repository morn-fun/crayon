import 'package:flutter/cupertino.dart';
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
      data.operator, p.cellPosition, node, p.cursor, data.index);
  final extra = data.extras;
  if (extra is! TextEditingValue) {
    throw NodeUnsupportedException(node.runtimeType,
        'typingWhileSelecting, extra is not TextEditingValue', data);
  }
  try {
    nodeWithCursor = innerNode
        .onEdit(EditingData(p.cursor, EventType.typing, ctx, extras: extra));
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
        e.operator);
  }
  return NodeWithCursor(
      node.updateCell(
          p.row, p.column, to(cell.update(index, to(nodeWithCursor.node)))),
      EditingCursor(
          data.index,
          TablePosition(
              p.cellPosition, nodeWithCursor.cursor as EditingCursor)));
}
