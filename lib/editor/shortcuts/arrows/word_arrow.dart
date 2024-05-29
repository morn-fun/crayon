import 'package:flutter/material.dart';
import '../../../editor/exception/editor_node.dart';
import '../../../editor/extension/node_context.dart';

import '../../core/context.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import 'arrows.dart';

class LeftWordArrowAction extends ContextAction<LeftWordArrowIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  BasicCursor get cursor => ac.cursor;

  LeftWordArrowAction(this.ac);

  @override
  void invoke(LeftWordArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      wordArrowOnLeft(operator, cursor);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

class RightWordArrowAction extends ContextAction<RightWordArrowIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  BasicCursor get cursor => ac.cursor;

  RightWordArrowAction(this.ac);

  @override
  void invoke(RightWordArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      wordArrowOnRight(operator, cursor);
    } catch (e) {
      logger.i('$runtimeType error:$e');
    }
  }
}

void wordArrowOnLeft(NodesOperator operator, BasicCursor cursor) {
  late NodePosition position;
  int index = -1;
  ArrowType t = ArrowType.lastWord;
  if (cursor is EditingCursor) {
    index = cursor.index;
    position = cursor.position;
  } else if (cursor is SelectingNodeCursor) {
    index = cursor.index;
    position = cursor.left;
    t = ArrowType.current;
  } else if (cursor is SelectingNodesCursor) {
    index = cursor.left.index;
    position = cursor.left.position;
    t = ArrowType.current;
  }
  if (index == -1) return;
  try {
    operator.onArrowAccept(
        AcceptArrowData(operator.getNode(index).id, t, position, t));
  } on ArrowLeftBeginException catch (e) {
    logger.e('${ArrowType.lastWord} error ${e.message}');
    final lastIndex = index - 1;
    if (lastIndex < 0) rethrow;
    operator.onArrowAccept(AcceptArrowData(operator.getNode(lastIndex).id,
        ArrowType.current, operator.getNode(lastIndex).endPosition, t));
  } on NodeNotFoundException catch (e) {
    logger.e('${ArrowType.lastWord} error ${e.message}');
    operator.onCursor(EditingCursor(index, position));
  }
}

void wordArrowOnRight(NodesOperator operator, BasicCursor cursor) {
  int index = -1;
  ArrowType t = ArrowType.nextWord;
  late NodePosition position;
  if (cursor is EditingCursor) {
    index = cursor.index;
    position = cursor.position;
  } else if (cursor is SelectingNodeCursor) {
    index = cursor.index;
    position = cursor.right;
    t = ArrowType.current;
  } else if (cursor is SelectingNodesCursor) {
    index = cursor.right.index;
    position = cursor.right.position;
    t = ArrowType.current;
  }
  if (index == -1) return;
  try {
    operator.onArrowAccept(
        AcceptArrowData(operator.getNode(index).id, t, position, t));
  } on ArrowRightEndException catch (e) {
    logger.e('${ArrowType.nextWord} error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > operator.nodeLength - 1) rethrow;
    operator.onArrowAccept(AcceptArrowData(operator.getNode(nextIndex).id,
        ArrowType.current, operator.getNode(nextIndex).beginPosition, t));
  } on NodeNotFoundException catch (e) {
    logger.e('${ArrowType.nextWord} error ${e.message}');
    operator.onCursor(EditingCursor(index, position));
  }
}
