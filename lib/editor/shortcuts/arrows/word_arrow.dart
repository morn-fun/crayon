import 'package:flutter/material.dart';
import '../../../editor/exception/editor_node.dart';
import '../../../editor/extension/node_context.dart';

import '../../core/context.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import 'arrows.dart';

class ArrowWordLastAction extends ContextAction<ArrowWordLastIntent> {
  final ActionOperator ac;

  ArrowWordLastAction(this.ac);

  @override
  void invoke(ArrowWordLastIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      wordArrowOnLast(ac.operator, ac.cursor);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class ArrowWordNextAction extends ContextAction<ArrowWordNextIntent> {
  final ActionOperator ac;

  ArrowWordNextAction(this.ac);

  @override
  void invoke(ArrowWordNextIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      wordArrowOnNext(ac.operator, ac.cursor);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

void wordArrowOnLast(NodesOperator operator, BasicCursor cursor) {
  EditingCursor? newCursor;
  ArrowType t = ArrowType.wordLast;
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
  } on ArrowLeftBeginException catch (e) {
    logger.e('${ArrowType.wordLast} error ${e.message}');
    final lastIndex = index - 1;
    if (lastIndex < 0) rethrow;
    operator.onArrowAccept(AcceptArrowData(
        operator.getNode(lastIndex).id,
        ArrowType.current,
        operator.getNode(lastIndex).endPosition.toCursor(lastIndex),
        t));
  } on NodeNotFoundException catch (e) {
    logger.e('${ArrowType.wordLast} error ${e.message}');
    operator.onCursor(newCursor);
  }
}

void wordArrowOnNext(NodesOperator operator, BasicCursor cursor) {
  EditingCursor? newCursor;
  ArrowType t = ArrowType.wordNext;
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
  } on ArrowRightEndException catch (e) {
    logger.e('${ArrowType.wordNext} error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > operator.nodeLength - 1) rethrow;
    operator.onArrowAccept(AcceptArrowData(
        operator.getNode(nextIndex).id,
        ArrowType.current,
        operator.getNode(nextIndex).beginPosition.toCursor(nextIndex),
        t));
  } on NodeNotFoundException catch (e) {
    logger.e('${ArrowType.wordNext} error ${e.message}');
    operator.onCursor(newCursor);
  }
}
