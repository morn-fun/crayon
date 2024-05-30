import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../../editor/extension/node_context.dart';
import '../../exception/editor_node.dart';
import 'arrows.dart';

class ArrowLeftSelectionAction extends ContextAction<ArrowLeftSelectionIntent> {
  final ActionOperator ac;

  ArrowLeftSelectionAction(this.ac);

  @override
  void invoke(ArrowLeftSelectionIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      arrowSelection(ac.operator, ac.cursor, ArrowType.selectionLeft);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class ArrowRightSelectionAction
    extends ContextAction<ArrowRightSelectionIntent> {
  final ActionOperator ac;

  ArrowRightSelectionAction(this.ac);

  @override
  void invoke(ArrowRightSelectionIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      arrowSelection(ac.operator, ac.cursor, ArrowType.selectionRight);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class ArrowUpSelectionAction extends ContextAction<ArrowUpSelectionIntent> {
  final ActionOperator ac;

  ArrowUpSelectionAction(this.ac);

  @override
  void invoke(ArrowUpSelectionIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      arrowSelection(ac.operator, ac.cursor, ArrowType.selectionUp);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class ArrowDownSelectionAction extends ContextAction<ArrowDownSelectionIntent> {
  final ActionOperator ac;

  ArrowDownSelectionAction(this.ac);

  @override
  void invoke(ArrowDownSelectionIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      arrowSelection(ac.operator, ac.cursor, ArrowType.selectionDown);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

void arrowSelection(
    NodesOperator operator, BasicCursor cursor, ArrowType type) {
  EditingCursor? newCursor;

  ArrowType t = type;
  if (cursor is EditingCursor) {
    newCursor = cursor;
  } else if (cursor is SelectingNodeCursor) {
    newCursor = cursor.endCursor;
  } else if (cursor is SelectingNodesCursor) {
    newCursor = cursor.end;
  }
  if (newCursor == null) {
    throw NodeUnsupportedException(
        operator.runtimeType, 'arrowSelection $type without cursor', cursor);
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
        ArrowType.selectionCurrent,
        operator.getNode(lastIndex).endPosition.toCursor(lastIndex),
        t));
  } on ArrowRightEndException catch (e) {
    logger.e('$type error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex >= operator.nodeLength) rethrow;
    operator.onArrowAccept(AcceptArrowData(
        operator.getNode(nextIndex).id,
        ArrowType.selectionCurrent,
        operator.getNode(nextIndex).beginPosition.toCursor(nextIndex),
        t));
  } on ArrowUpTopException catch (e) {
    logger.e('$type error ${e.message}');
    final lastIndex = index - 1;
    if (lastIndex < 0) rethrow;
    final node = operator.getNode(lastIndex);
    operator.onArrowAccept(AcceptArrowData(node.id, ArrowType.selectionCurrent,
        node.endPosition.toCursor(index), t,
        extras: e.offset));
  } on ArrowDownBottomException catch (e) {
    logger.e('$type error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > operator.nodeLength - 1) rethrow;
    final node = operator.getNode(nextIndex);
    operator.onArrowAccept(AcceptArrowData(node.id, ArrowType.selectionCurrent,
        node.beginPosition.toCursor(index), t,
        extras: e.offset));
  }
}
