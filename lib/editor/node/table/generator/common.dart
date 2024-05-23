import 'package:flutter/material.dart';

import '../../../command/modification.dart';
import '../../../core/context.dart';
import '../../../core/copier.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../table.dart';
import '../table_cell.dart';

NodeWithCursor operateWhileEditing<T extends Intent>(
    EditingData<TablePosition> data,
    TableNode node,
    ValueChanged<ActionContext> onAction) {
  final p = data.position;
  final ctx = data.context;
  final context = buildTableCellNodeContext(
      ctx, p.cellPosition, node, p.cursor, data.index);
  onAction.call(ActionContext(context, () => p.cursor));
  throw NodeUnsupportedException(node.runtimeType, 'operateWhileEditing', null);
}

SingleNodeCursor<TablePosition> _cursorToCursor(
    BasicCursor cursor, CellPosition cellPosition, int index) {
  if (cursor is EditingCursor) {
    return EditingCursor(index, TablePosition(cellPosition, cursor));
  } else if (cursor is SelectingNodeCursor) {
    final i = cursor.index;
    return SelectingNodeCursor(
        index,
        TablePosition(cellPosition, EditingCursor(i, cursor.left)),
        TablePosition(cellPosition, EditingCursor(i, cursor.right)));
  } else if (cursor is SelectingNodesCursor) {
    return SelectingNodeCursor(index, TablePosition(cellPosition, cursor.left),
        TablePosition(cellPosition, cursor.right));
  }
  throw NodeUnsupportedException(cursor.runtimeType,
      'from cursor:$cursor to table cursor', '$cellPosition,  index:$index');
}

TableCellNodeContext buildTableCellNodeContext(NodeContext ctx, CellPosition p,
    TableNode node, BasicCursor cursor, int index) {
  return node.buildContext(
    position: p,
    cursor: cursor,
    listeners: ctx.listeners,
    onReplace: (v) {
      ctx.execute(ModifyNode(NodeWithCursor(
          node.updateCell(p.row, p.column,
              (t) => t.replaceMore(v.begin, v.end, v.newNodes)),
          _cursorToCursor(v.cursor, p, index))));
    },
    onUpdate: (v) {
      ctx.execute(ModifyNode(NodeWithCursor(
          node.updateCell(
              p.row, p.column, (t) => t.update(v.index, (n) => v.node)),
          _cursorToCursor(v.cursor, p, index))));
    },
    onBasicCursor: (newCursor) =>
        ctx.onCursor(_cursorToCursor(newCursor, p, index)),
    editingOffset: (v) => ctx.onEditingOffset(v),
    onNodeUpdate: (v) {
      ctx.execute(ModifyNodeWithoutChangeCursor(
          index,
          node.updateCell(
              p.row, p.column, (t) => t.update(v.index, to(v.node)))));
    },
    onPan: (v) => ctx.onPanUpdate(EditingCursor(index, TablePosition(p, v))),
  );
}
