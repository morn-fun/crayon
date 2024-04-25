import 'package:flutter/material.dart';
import '../../editor/command/replace.dart';
import '../../editor/exception/editor_node_exception.dart';
import '../../editor/extension/int_extension.dart';

import '../command/selecting_nodes/depth.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import '../node/position_data.dart';

class TabIntent extends Intent {
  const TabIntent();
}

class ShiftTabIntent extends Intent {
  const ShiftTabIntent();
}

class TabAction extends ContextAction<TabIntent> {
  final EditorContext editorContext;

  TabAction(this.editorContext);

  @override
  void invoke(TabIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = editorContext.cursor;
    final controller = editorContext.controller;
    try {
      if (cursor is EditingCursor) {
        final index = cursor.index;
        final node = controller.getNode(index);
        int lastDepth = index == 0 ? 0 : controller.getNode(index - 1).depth;
        final r = node.onEdit(EditingData(
            cursor.position, EventType.increaseDepth,
            extras: lastDepth));
        editorContext.execute(ReplaceNode(
            Replace(index, index + 1, [r.node], r.position.toCursor(index))));
      } else if (cursor is SelectingNodeCursor) {
        final index = cursor.index;
        int lastDepth = index == 0 ? 0 : controller.getNode(index - 1).depth;
        final r = controller.getNode(cursor.index).onSelect(SelectingData(
            SelectingPosition(cursor.begin, cursor.end),
            EventType.increaseDepth,
            extras: lastDepth));
        editorContext.execute(ReplaceNode(
            Replace(index, index + 1, [r.node], r.position.toCursor(index))));
      } else if (cursor is SelectingNodesCursor) {
        editorContext.execute(IncreaseNodesDepth(cursor));
      }
    } on DepthNotAbleToIncreaseException catch (e) {
      logger.e('$runtimeType, ${e.message}');
    }
  }
}

class ShiftTabAction extends ContextAction<ShiftTabIntent> {
  final EditorContext editorContext;

  ShiftTabAction(this.editorContext);

  @override
  void invoke(ShiftTabIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = editorContext.cursor;
    final controller = editorContext.controller;
    try {
      if (cursor is EditingCursor) {
        final index = cursor.index;
        final node = controller.getNode(index);
        final r =
            node.onEdit(EditingData(cursor.position, EventType.decreaseDepth));
        editorContext.execute(ReplaceNode(
            Replace(index, index + 1, [r.node], r.position.toCursor(index))));
      } else if (cursor is SelectingNodeCursor) {
        final index = cursor.index;
        final r = controller.getNode(index).onSelect(SelectingData(
            SelectingPosition(cursor.begin, cursor.end),
            EventType.decreaseDepth));
        editorContext.execute(ReplaceNode(
            Replace(index, index + 1, [r.node], r.position.toCursor(index))));
      } else if (cursor is SelectingNodesCursor) {
        editorContext.execute(DecreaseNodesDepth(cursor));
      }
    } on DepthNeedDecreaseMoreException catch (e) {
      logger.e('$runtimeType, ${e.message}');
      if (cursor is! SingleNodeCursor) return;
      final controller = editorContext.controller;
      int index = cursor.index;
      final node = controller.getNode(index);
      final nodes = <EditorNode>[node.newNode(depth: node.depth.decrease())];
      correctDepth(controller, index + 1, e.depth, nodes);
      editorContext.execute(ReplaceNode(
          Replace(cursor.index, cursor.index + nodes.length, nodes, cursor)));
    }
  }
}
