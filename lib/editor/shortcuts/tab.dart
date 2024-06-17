import 'package:flutter/material.dart';
import '../../editor/command/replacement.dart';
import '../../editor/exception/editor_node.dart';
import '../../editor/extension/int.dart';

import '../command/selecting/depth.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import '../core/logger.dart';
import '../cursor/basic.dart';
import '../node/basic.dart';
import '../../../editor/extension/node_context.dart';

class TabIntent extends Intent {
  const TabIntent();
}

class ShiftTabIntent extends Intent {
  const ShiftTabIntent();
}

class TabAction extends ContextAction<TabIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  BasicCursor get cursor => operator.cursor;

  TabAction(this.ac);

  @override
  void invoke(TabIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = this.cursor;
    try {
      if (cursor is EditingCursor) {
        final index = cursor.index;
        final node = operator.getNode(index);
        int lastDepth = index == 0 ? 0 : operator.getNode(index - 1).depth;
        final r = node.onEdit(EditingData(
            cursor, EventType.increaseDepth, operator,
            extras: lastDepth));
        operator.execute(
            ReplaceNode(Replace(index, index + 1, [r.node], r.cursor)));
      } else if (cursor is SelectingNodeCursor) {
        final index = cursor.index;
        int lastDepth = index == 0 ? 0 : operator.getNode(index - 1).depth;
        final r = operator.getNode(cursor.index).onSelect(SelectingData(
            cursor, EventType.increaseDepth, operator,
            extras: lastDepth));
        operator.execute(
            ReplaceNode(Replace(index, index + 1, [r.node], r.cursor)));
      } else if (cursor is SelectingNodesCursor) {
        operator.execute(IncreaseNodesDepth(cursor));
      }
    } on NodeUnsupportedException catch (e) {
      logger.e('$runtimeType, ${e.message}');
    }
  }
}

class ShiftTabAction extends ContextAction<ShiftTabIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  BasicCursor get cursor => operator.cursor;

  ShiftTabAction(this.ac);

  @override
  void invoke(ShiftTabIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = this.cursor;
    try {
      if (cursor is EditingCursor) {
        final index = cursor.index;
        final node = operator.getNode(index);
        final r =
            node.onEdit(EditingData(cursor, EventType.decreaseDepth, operator));
        operator.execute(
            ReplaceNode(Replace(index, index + 1, [r.node], r.cursor)));
      } else if (cursor is SelectingNodeCursor) {
        final index = cursor.index;
        final r = operator
            .getNode(index)
            .onSelect(SelectingData(cursor, EventType.decreaseDepth, operator));
        operator.execute(
            ReplaceNode(Replace(index, index + 1, [r.node], r.cursor)));
      } else if (cursor is SelectingNodesCursor) {
        operator.execute(DecreaseNodesDepth(cursor));
      }
    } on DepthNeedDecreaseMoreException catch (e) {
      logger.e('$runtimeType, ${e.message}');
      if (cursor is! SingleNodeCursor) return;
      int index = cursor.index;
      final node = operator.getNode(index);
      final nodes = <EditorNode>[node.newNode(depth: node.depth.decrease())];
      correctDepth(operator.nodeLength, (i) => operator.getNode(i), index + 1,
          e.depth, nodes);
      operator.execute(ReplaceNode(
          Replace(cursor.index, cursor.index + nodes.length, nodes, cursor)));
    } on NodeUnsupportedException catch (e) {
      logger.e('$runtimeType, ${e.message}');
    }
  }
}
