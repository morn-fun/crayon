import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../../editor/extension/node_context.dart';
import '../../exception/editor_node.dart';
import 'arrows.dart';

class LineBeginArrowAction extends ContextAction<LineBeginArrowIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  BasicCursor get cursor => ac.cursor;

  LineBeginArrowAction(this.ac);

  @override
  void invoke(LineBeginArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      lineArrowOnBegin(operator, cursor);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class LineEndArrowAction extends ContextAction<LineEndArrowIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  BasicCursor get cursor => ac.cursor;

  LineEndArrowAction(this.ac);

  @override
  void invoke(LineEndArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      lineArrowOnEnd(operator, cursor);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

void lineArrowOnBegin(NodesOperator operator, BasicCursor cursor) {
  EditingCursor? newCursor;
  ArrowType t = ArrowType.lineBegin;
  if (cursor is EditingCursor) {
    newCursor = cursor;
  } else if (cursor is SelectingNodeCursor) {
    newCursor = cursor.leftCursor;
    t = ArrowType.current;
  } else if (cursor is SelectingNodesCursor) {
    newCursor = cursor.left;
    t = ArrowType.current;
  }
  if (newCursor == null) return;
  final index = newCursor.index;
  try {
    operator.onArrowAccept(
        AcceptArrowData(operator.getNode(index).id, t, newCursor, t));
  } on NodeUnsupportedException catch (e) {
    logger.e('lineArrowOnBegin error: ${e.message}');
  }
}

void lineArrowOnEnd(NodesOperator operator, BasicCursor cursor) {
  EditingCursor? newCursor;
  ArrowType t = ArrowType.lineEnd;
  if (cursor is EditingCursor) {
    newCursor = cursor;
  } else if (cursor is SelectingNodeCursor) {
    newCursor = cursor.rightCursor;
    t = ArrowType.current;
  } else if (cursor is SelectingNodesCursor) {
    newCursor = cursor.right;
    t = ArrowType.current;
  }
  if (newCursor == null) return;
  final index = newCursor.index;
  try {
    operator.onArrowAccept(
        AcceptArrowData(operator.getNode(index).id, t, newCursor, t));
  } on NodeUnsupportedException catch (e) {
    logger.e('lineArrowOnEnd error: ${e.message}');
  }
}
