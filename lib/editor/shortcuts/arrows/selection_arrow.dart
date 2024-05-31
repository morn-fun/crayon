import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../../editor/extension/node_context.dart';
import '../../exception/editor_node.dart';
import 'arrows.dart';

class ArrowSelectionLeftAction extends ContextAction<ArrowSelectionLeftIntent> {
  final ActionOperator ac;

  ArrowSelectionLeftAction(this.ac);

  @override
  void invoke(ArrowSelectionLeftIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      onArrowSelection(ac.operator, ac.cursor, ArrowType.selectionLeft);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class ArrowSelectionRightAction
    extends ContextAction<ArrowSelectionRightIntent> {
  final ActionOperator ac;

  ArrowSelectionRightAction(this.ac);

  @override
  void invoke(ArrowSelectionRightIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      onArrowSelection(ac.operator, ac.cursor, ArrowType.selectionRight);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class ArrowSelectionUpAction extends ContextAction<ArrowSelectionUpIntent> {
  final ActionOperator ac;

  ArrowSelectionUpAction(this.ac);

  @override
  void invoke(ArrowSelectionUpIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      onArrowSelection(ac.operator, ac.cursor, ArrowType.selectionUp);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class ArrowSelectionDownAction extends ContextAction<ArrowSelectionDownIntent> {
  final ActionOperator ac;

  ArrowSelectionDownAction(this.ac);

  @override
  void invoke(ArrowSelectionDownIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      onArrowSelection(ac.operator, ac.cursor, ArrowType.selectionDown);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

void onArrowSelection(
    NodesOperator operator, BasicCursor cursor, ArrowType type) {
  EditingCursor? newCursor;
  ArrowType t = type;
  if (cursor is EditingCursor) {
    newCursor = cursor;
  } else if (cursor is SelectingNodeCursor) {
    newCursor = cursor.endCursor;
  } else if (cursor is SelectingNodesCursor) {
    final endNode = operator.getNode(cursor.endIndex);
    newCursor = cursor.end;
    if (t == ArrowType.selectionLeft || t == ArrowType.selectionUp) {
      if (endNode is! RichTextNode) {
        newCursor = EditingCursor(cursor.endIndex, endNode.beginPosition);
      }
    } else {
      if (endNode is! RichTextNode) {
        newCursor = EditingCursor(cursor.endIndex, endNode.endPosition);
      }
    }
  }
  if (newCursor == null) {
    throw NodeUnsupportedException(
        operator.runtimeType, 'onArrowSelection $type without cursor', cursor);
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
