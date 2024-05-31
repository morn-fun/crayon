import 'package:flutter/material.dart';
import '../../../editor/exception/editor_node.dart';
import '../../../editor/extension/node_context.dart';

import '../../core/context.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../node/rich_text/rich_text.dart';
import 'arrows.dart';

class ArrowSelectionWordLastAction
    extends ContextAction<ArrowSelectionWordLastIntent> {
  final ActionOperator ac;

  ArrowSelectionWordLastAction(this.ac);

  @override
  void invoke(ArrowSelectionWordLastIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      onArrowWordSelection(ac.operator, ac.cursor, ArrowType.selectionWordLast);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class ArrowSelectionWordNextAction
    extends ContextAction<ArrowSelectionWordNextIntent> {
  final ActionOperator ac;

  ArrowSelectionWordNextAction(this.ac);

  @override
  void invoke(ArrowSelectionWordNextIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      onArrowWordSelection(ac.operator, ac.cursor, ArrowType.selectionWordNext);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

void onArrowWordSelection(
    NodesOperator operator, BasicCursor cursor, ArrowType type) {
  ArrowType t = type;
  EditingCursor? newCursor;
  if (cursor is EditingCursor) {
    newCursor = cursor;
  } else if (cursor is SelectingNodeCursor) {
    newCursor = cursor.endCursor;
  } else if (cursor is SelectingNodesCursor) {
    final endNode = operator.getNode(cursor.endIndex);
    newCursor = cursor.end;
    if (t == ArrowType.selectionWordLast) {
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
    throw NodeUnsupportedException(operator.runtimeType,
        'onArrowWordSelection $type without cursor', cursor);
  }
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
        ArrowType.selectionCurrent,
        operator.getNode(lastIndex).endPosition.toCursor(lastIndex),
        t));
  } on ArrowRightEndException catch (e) {
    logger.e('$type onArrowWordSelection error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > operator.nodeLength - 1) rethrow;
    operator.onArrowAccept(AcceptArrowData(
        operator.getNode(nextIndex).id,
        ArrowType.selectionCurrent,
        operator.getNode(nextIndex).beginPosition.toCursor(nextIndex),
        t));
  }
}
