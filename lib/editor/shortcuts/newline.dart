import 'package:flutter/material.dart';
import '../../editor/command/replacement.dart';
import '../../editor/exception/editor_node.dart';

import '../command/modification.dart';
import '../command/selecting/newline.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import '../core/logger.dart';
import '../cursor/basic.dart';
import '../node/basic.dart';

class NewlineIntent extends Intent {
  const NewlineIntent();
}

class NewlineAction extends ContextAction<NewlineIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  BasicCursor get cursor => ac.cursor;

  NewlineAction(this.ac);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final c = cursor;
    if (c is EditingCursor) {
      try {
        final r = operator
            .getNode(c.index)
            .onEdit(EditingData(c, EventType.newline, operator));
        operator.execute(ModifyNode(r));
      } on NewlineRequiresNewNode catch (e) {
        logger.e('$runtimeType $e');
        int index = c.index;
        final current = operator.getNode(index);
        final left = current.frontPartNode(c.position);
        final right = current.rearPartNode(c.position, newId: randomNodeId);
        operator.execute(ReplaceNode(Replace(index, index + 1, [left, right],
            EditingCursor(index + 1, right.beginPosition))));
      } on NewlineRequiresNewSpecialNode catch (e) {
        int index = c.index;
        operator.execute(ReplaceNode(Replace(index, index + 1, e.newNodes,
            EditingCursor(index + e.newNodes.length - 1, e.position))));
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    } else if (c is SelectingNodeCursor) {
      try {
        final r = operator
            .getNode(c.index)
            .onSelect(SelectingData(c, EventType.newline, operator));
        operator.execute(ModifyNode(r));
      } on NewlineRequiresNewNode catch (e) {
        logger.e('$runtimeType $e');
        int index = c.index;
        final current = operator.getNode(index);
        final left = current.frontPartNode(c.left);
        final right = current.rearPartNode(c.right, newId: randomNodeId);
        operator.execute(ReplaceNode(Replace(index, index + 1, [left, right],
            EditingCursor(index + 1, right.beginPosition))));
      } on NewlineRequiresNewSpecialNode catch (e) {
        int index = c.index;
        operator.execute(ReplaceNode(Replace(index, index + 1, e.newNodes,
            EditingCursor(index + e.newNodes.length - 1, e.position))));
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    } else if (c is SelectingNodesCursor) {
      operator.execute(InsertNewLineWhileSelectingNodes(c));
    }
  }
}
