import 'package:flutter/material.dart';

import '../../../editor/extension/node_context.dart';
import '../../core/context.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import 'arrows.dart';

class LeftArrowAction extends ContextAction<LeftArrowIntent> {
  final ActionOperator ac;

  LeftArrowAction(this.ac);

  @override
  void invoke(LeftArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      onArrow(ac.operator, ac.cursor, ArrowType.left);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class RightArrowAction extends ContextAction<RightArrowIntent> {
  final ActionOperator ac;

  RightArrowAction(this.ac);

  @override
  void invoke(RightArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      onArrow(ac.operator, ac.cursor, ArrowType.right);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class UpArrowAction extends ContextAction<UpArrowIntent> {
  final ActionOperator ac;

  UpArrowAction(this.ac);

  @override
  void invoke(UpArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      onArrow(ac.operator, ac.cursor, ArrowType.up);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class DownArrowAction extends ContextAction<DownArrowIntent> {
  final ActionOperator ac;

  DownArrowAction(this.ac);

  @override
  void invoke(DownArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      onArrow(ac.operator, ac.cursor, ArrowType.down);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

void onArrow(NodesOperator operator, BasicCursor cursor, ArrowType type) {
  ArrowType t = type;
  EditingCursor? newCursor;
  if (cursor is EditingCursor) {
    newCursor = cursor;
  } else if (cursor is SelectingNodeCursor) {
    newCursor = cursor.rightCursor;
    t = ArrowType.current;
  } else if (cursor is SelectingNodesCursor) {
    newCursor = cursor.right;
    t = ArrowType.current;
  }
  if (newCursor == null) {
    throw NodeUnsupportedException(
        operator.runtimeType, 'onArrow $type without cursor', cursor);
  }
  final index = newCursor.index;
  try {
    operator.onArrowAccept(
        AcceptArrowData(operator.getNode(index).id, t, newCursor, t));
  } on ArrowLeftBeginException catch (e) {
    logger.e('$type error ${e.message}');
    final lastIndex = index - 1;
    if (lastIndex < 0) rethrow;
    operator.onArrowAccept(AcceptArrowData(
        operator.getNode(lastIndex).id,
        ArrowType.current,
        operator.getNode(lastIndex).endPosition.toCursor(lastIndex),
        t));
  } on ArrowUpTopException catch (e) {
    logger.e('$type error ${e.message}');
    final lastIndex = index - 1;
    if (lastIndex < 0) rethrow;
    final node = operator.getNode(lastIndex);
    operator.onArrowAccept(AcceptArrowData(
        node.id, ArrowType.current, node.endPosition.toCursor(index), t,
        extras: e.offset));
  } on ArrowRightEndException catch (e) {
    logger.e('$type error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > operator.nodeLength - 1) rethrow;
    operator.onArrowAccept(AcceptArrowData(
        operator.getNode(nextIndex).id,
        ArrowType.current,
        operator.getNode(nextIndex).beginPosition.toCursor(nextIndex),
        t));
  } on ArrowDownBottomException catch (e) {
    logger.e('$type error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > operator.nodeLength - 1) rethrow;
    final node = operator.getNode(nextIndex);
    operator.onArrowAccept(AcceptArrowData(
        node.id, ArrowType.current, node.beginPosition.toCursor(index), t,
        extras: e.offset));
  } on NodeNotFoundException catch (e) {
    logger.e('$type error ${e.message}');
    operator.onCursor(newCursor);
  }
}
