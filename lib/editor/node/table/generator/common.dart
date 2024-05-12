import 'package:flutter/material.dart';

import '../../../core/context.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../table.dart';

NodeWithPosition operateWhileEditing<T extends Intent>(
    EditingData<TablePosition> data,
    TableNode node,
    ValueChanged<ActionContext> onAction) {
  final p = data.position;
  final cell = node.getCell(p.cellPosition);
  final context =
      data.context.getChildContext(cell.id)!;
  onAction
      .call(ActionContext(context, () => EditingCursor(p.index, p.position)));
  throw NodeUnsupportedException(node.runtimeType, 'operateWhileEditing', null);
}
