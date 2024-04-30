import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/logger.dart';
import '../cursor/basic.dart';
import '../exception/editor_node.dart';
import '../node/basic.dart';
import '../cursor/node_position.dart';

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class SelectAllAction extends ContextAction<SelectAllIntent> {
  final NodeContext nodeContext;

  SelectAllAction(this.nodeContext);

  @override
  void invoke(SelectAllIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = nodeContext.cursor;
    if (cursor is EditingCursor) {
      try {
        final r = nodeContext.getNode(cursor.index).onEdit(EditingData(
            cursor.position, EventType.selectAll, nodeContext.listeners));
        nodeContext.updateCursor(r.toCursor(cursor.index));
      } on EmptyNodeToSelectAllException {
        nodeContext.updateCursor(nodeContext.selectAllCursor);
      }
    } else if (cursor is SelectingNodeCursor) {
      final node = nodeContext.getNode(cursor.index);
      if (node.beginPosition == cursor.begin &&
          node.endPosition == cursor.end) {
        nodeContext.updateCursor(nodeContext.selectAllCursor);
      } else {
        final r = node.onSelect(SelectingData(
            SelectingPosition(cursor.begin, cursor.end),
            EventType.selectAll,
            nodeContext.listeners));
        nodeContext.updateCursor(r.toCursor(cursor.index));
      }
    } else if (cursor is SelectingNodesCursor) {
      final allNodesCursor = nodeContext.selectAllCursor;
      if (cursor == allNodesCursor) return;
      nodeContext.updateCursor(allNodesCursor);
    }
  }
}
