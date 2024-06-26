import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../../editor/extension/node_context.dart';
import '../../exception/editor_node.dart';
import 'arrows.dart';

class ArrowLineBeginAction extends ContextAction<ArrowLineBeginIntent> {
  final ActionOperator ac;

  ArrowLineBeginAction(this.ac);

  @override
  void invoke(ArrowLineBeginIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      arrowOnLine(ac.operator, ac.operator.cursor, ArrowType.lineBegin);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class ArrowLineEndAction extends ContextAction<ArrowLineEndIntent> {
  final ActionOperator ac;

  ArrowLineEndAction(this.ac);

  @override
  void invoke(ArrowLineEndIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      arrowOnLine(ac.operator, ac.operator.cursor, ArrowType.lineEnd);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

void arrowOnLine(NodesOperator operator, BasicCursor cursor, ArrowType type,
    {bool retried = false}) {
  EditingCursor? newCursor;
  ArrowType t = type;
  if (cursor is EditingCursor) {
    newCursor = cursor;
  } else if (cursor is SelectingNodeCursor) {
    newCursor =
        (type == ArrowType.lineBegin) ? cursor.leftCursor : cursor.endCursor;
    t = ArrowType.current;
  } else if (cursor is SelectingNodesCursor) {
    newCursor = (type == ArrowType.lineBegin) ? cursor.left : cursor.right;
    t = ArrowType.current;
  }
  if (newCursor == null) {
    throw NodeUnsupportedException(
        operator.runtimeType, 'arrowOnLine $type without cursor', cursor);
  }
  final index = newCursor.index;
  try {
    operator.onArrowAccept(
        AcceptArrowData(operator.getNode(index).id, t, newCursor, t));
  } on NodeNotFoundException {
    if (retried) return;
    operator.scrollTo(newCursor.index)?.then((v) {
      arrowOnLine(operator, cursor, type, retried: true);
    });
  }
}
