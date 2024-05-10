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
  final ActionContext ac;

  NodeContext get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  SelectAllAction(this.ac);

  @override
  void invoke(SelectAllIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = this.cursor;
    if (cursor is EditingCursor) {
      try {
        final r = nodeContext.getNode(cursor.index).onEdit(
            EditingData(cursor.position, EventType.selectAll, nodeContext));
        nodeContext.onCursor(r.toCursor(cursor.index));
      } on EmptyNodeToSelectAllException {
        nodeContext.onCursor(nodeContext.selectAllCursor);
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    } else if (cursor is SelectingNodeCursor) {
      final node = nodeContext.getNode(cursor.index);
      if (node.beginPosition == cursor.begin &&
          node.endPosition == cursor.end) {
        nodeContext.onCursor(nodeContext.selectAllCursor);
      } else {
        try {
          final r = node.onSelect(SelectingData(
              SelectingPosition(cursor.begin, cursor.end),
              EventType.selectAll,
              nodeContext));
          nodeContext.onCursor(r.toCursor(cursor.index));
        } on NodeUnsupportedException catch (e) {
          logger.e('$runtimeType, ${e.message}');
        }
      }
    } else if (cursor is SelectingNodesCursor) {
      final allNodesCursor = nodeContext.selectAllCursor;
      if (cursor == allNodesCursor) return;
      nodeContext.onCursor(allNodesCursor);
    }
  }
}
