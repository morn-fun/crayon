import 'package:flutter/material.dart';

import '../../../core/context.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../basic.dart';
import '../table.dart';

NodeWithPosition operateWhileEditing<T extends Intent>(
    EditingData<TablePosition> data,
    TableNode node,
    ValueChanged<NodeContext> onAction) {
  final p = data.position;
  final cell = node.getCellByPosition(p);
  final index = p.index;
  BasicCursor cursor = EditingCursor(index, p.position);
  var newCell = cell;
  final listeners = data.listeners;
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
  onAction.call(context);
  return NodeWithPosition(
      node.updateCell(p.row, p.column, (t) => newCell), p.fromCursor(cursor));
}
