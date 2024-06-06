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
      onArrowWord(ac.operator, ac.operator.cursor, ArrowType.wordLast);
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
      onArrowWord(ac.operator, ac.operator.cursor, ArrowType.wordNext);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

void onArrowWord(NodesOperator operator, BasicCursor cursor, ArrowType type,
    {bool retried = false}) {
  EditingCursor? newCursor;
  ArrowType t = type;
  if (cursor is EditingCursor) {
    newCursor = cursor;
  } else if (cursor is SelectingNodeCursor) {
    newCursor = cursor.endCursor;
    newCursor =
        (type == ArrowType.wordLast) ? cursor.leftCursor : cursor.endCursor;
    t = ArrowType.current;
  } else if (cursor is SelectingNodesCursor) {
    newCursor = (type == ArrowType.wordLast) ? cursor.left : cursor.right;
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
  } on ArrowRightEndException catch (e) {
    logger.e('$type onArrowWord error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > operator.nodeLength - 1) rethrow;
    operator.onArrowAccept(AcceptArrowData(
        operator.getNode(nextIndex).id,
        ArrowType.current,
        operator.getNode(nextIndex).beginPosition.toCursor(nextIndex),
        t));
  } on NodeNotFoundException catch (e) {
    logger.e('$type onArrowWord error ${e.message}');
    if (retried) return;
    operator.listeners.scrollTo(newCursor.index)?.then((v) {
      onArrowWord(operator, cursor, type, retried: true);
    });
  }
}
