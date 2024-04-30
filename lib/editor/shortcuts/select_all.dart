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
  final EditorContext editorContext;

  SelectAllAction(this.editorContext);

  @override
  void invoke(SelectAllIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final controller = editorContext.controller;
    final cursor = editorContext.cursor;
    if (cursor is EditingCursor) {
      try {
        final r = controller
            .getNode(cursor.index)
            .onEdit(EditingData(cursor.position, EventType.selectAll));
        controller.updateCursor(r.toCursor(cursor.index));
      } on EmptyNodeToSelectAllException {
        controller.updateCursor(controller.selectAllCursor);
      }
    } else if (cursor is SelectingNodeCursor) {
      final node = controller.getNode(cursor.index);
      if (node.beginPosition == cursor.begin &&
          node.endPosition == cursor.end) {
        controller.updateCursor(controller.selectAllCursor);
      } else {
        final r = node.onSelect(SelectingData(
            SelectingPosition(cursor.begin, cursor.end), EventType.selectAll));
        controller.updateCursor(r.toCursor(cursor.index));
      }
    } else if (cursor is SelectingNodesCursor) {
      final allNodesCursor = controller.selectAllCursor;
      if (cursor == allNodesCursor) return;
      controller.updateCursor(allNodesCursor);
    }
  }
}
