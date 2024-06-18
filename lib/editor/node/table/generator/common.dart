import 'package:flutter/material.dart' hide TableCell;

import '../../../../editor/node/rich_text/rich_text.dart';
import '../../../../editor/core/listener_collection.dart';
import '../../../command/modification.dart';
import '../../../core/context.dart';
import '../../../core/copier.dart';
import '../../../core/editor_controller.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../table.dart';
import '../table_cell.dart';

NodeWithCursor operateWhileEditing<T extends Intent>(
    EditingData<TablePosition> data,
    TableNode node,
    ValueChanged<ActionOperator> onAction) {
  final p = data.position;
  final opt = data.operator;
  final context = buildTableCellNodeContext(
      opt, p.cellPosition, node, p.cursor, data.index);
  onAction.call(ActionOperator(context));
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

TableCellNodeContext buildTableCellNodeContext(NodesOperator ctx,
    CellPosition p, TableNode node, BasicCursor cursor, int index) {
  final cell = node.getCell(p);
  final childListener =
      ctx.listeners.getListener(cell.id) ?? ListenerCollection();

  return TableCellNodeContext(
      cell: cell,
      cursor: cursor,
      operation: (v) {
        if (v is Replace) {
          ctx.execute(ModifyNode(NodeWithCursor(
              node.updateCell(p.row, p.column,
                  (t) => t.replaceMore(v.begin, v.end, v.newNodes)),
              _cursorToCursor(v.cursor, p, index))));
        } else if (v is Update) {
          ctx.execute(ModifyNode(NodeWithCursor(
              node.updateCell(
                  p.row, p.column, (t) => t.update(v.index, (n) => v.node)),
              _cursorToCursor(v.cursor, p, index))));
        } else if (v is MoveTo) {
          ctx.execute(ModifyNodeWithNoneCursor(index,
              node.updateCell(p.row, p.column, (t) => t.moveTo(v.from, v.to))));
        }
      },
      onBasicCursor: (newCursor) {
        if (newCursor is NoneCursor) {
          ctx.onCursor(newCursor);
        } else {
          ctx.onCursor(_cursorToCursor(newCursor, p, index));
        }
      },
      editingOffset: (v) => ctx.onCursorOffset(v),
      onNodeUpdate: (v) {
        ctx.execute(ModifyNodeWithoutChangeCursor(
            index,
            node.updateCell(
                p.row, p.column, (t) => t.update(v.index, to(v.node)))));
      },
      onPan: (v) {
        ctx.onPanUpdate(EditingCursor(index, TablePosition(p, v)));
      },
      listeners: childListener);
}

BasicCursor buildTableCellCursor(
    TableCell cell, EditingCursor begin, EditingCursor end) {
  if (begin.index == end.index) {
    return SelectingNodeCursor(begin.index, begin.position, end.position);
  } else {
    var left = begin.isLowerThan(end) ? begin : end;
    var right = begin.isLowerThan(end) ? end : begin;
    final leftNode = cell.getNode(left.index);
    final rightNode = cell.getNode(right.index);
    if (leftNode is! RichTextNode) {
      left = EditingCursor(left.index, leftNode.beginPosition);
    }
    if (rightNode is! RichTextNode) {
      right = EditingCursor(right.index, rightNode.endPosition);
    }
    return SelectingNodesCursor(left, right);
  }
}
