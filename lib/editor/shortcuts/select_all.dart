import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/logger.dart';
import '../cursor/basic.dart';
import '../exception/editor_node.dart';
import '../node/basic.dart';

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class SelectAllAction extends ContextAction<SelectAllIntent> {
  final ActionContext ac;

  NodesOperator get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  SelectAllAction(this.ac);

  @override
  void invoke(SelectAllIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = this.cursor;
    if (cursor is EditingCursor) {
      try {
        final r = nodeContext
            .getNode(cursor.index)
            .onEdit(EditingData(cursor, EventType.selectAll, nodeContext));
        nodeContext.onCursor(r.cursor);
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
          final r = node.onSelect(
              SelectingData(cursor, EventType.selectAll, nodeContext));
          nodeContext.onCursor(r.cursor);
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
