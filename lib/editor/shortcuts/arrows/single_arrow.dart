import 'package:flutter/material.dart';

import '../../../editor/extension/node_context.dart';
import '../../core/context.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import 'arrows.dart';

class LeftArrowAction extends ContextAction<LeftArrowIntent> {
  final ActionContext ac;

  NodeContext get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  LeftArrowAction(this.ac);

  @override
  void invoke(LeftArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    arrowOnLeftOrUp(ArrowType.left, nodeContext, runtimeType, cursor);
  }
}

class RightArrowAction extends ContextAction<RightArrowIntent> {
  final ActionContext ac;

  NodeContext get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  RightArrowAction(this.ac);

  @override
  void invoke(RightArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    arrowOnRightOrDown(ArrowType.right, nodeContext, runtimeType, cursor);
  }
}

class UpArrowAction extends ContextAction<UpArrowIntent> {
  final ActionContext ac;

  NodeContext get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  UpArrowAction(this.ac);

  @override
  void invoke(UpArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    arrowOnLeftOrUp(ArrowType.up, nodeContext, runtimeType, cursor);
  }
}

class DownArrowAction extends ContextAction<DownArrowIntent> {
  final ActionContext ac;

  NodeContext get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  DownArrowAction(this.ac);

  @override
  void invoke(DownArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    arrowOnRightOrDown(ArrowType.down, nodeContext, runtimeType, cursor);
  }
}

void arrowOnLeftOrUp(ArrowType type, NodeContext nodeContext, Type actionType,
    BasicCursor cursor) {
  int index = -1;
  late NodePosition position;
  ArrowType t = type;
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
    nodeContext.onArrowAccept(
        AcceptArrowData(nodeContext.getNode(index).id, t, position));
  } on ArrowLeftBeginException catch (e) {
    logger.e('$actionType error ${e.message}');
    final lastIndex = index - 1;
    if (lastIndex < 0) return;
    nodeContext.onArrowAccept(AcceptArrowData(nodeContext.getNode(lastIndex).id,
        ArrowType.current, nodeContext.getNode(lastIndex).endPosition));
  } on ArrowUpTopException catch (e) {
    logger.e('$actionType error ${e.message}');
    final lastIndex = index - 1;
    if (lastIndex < 0) return;
    final node = nodeContext.getNode(lastIndex);
    nodeContext.onArrowAccept(AcceptArrowData(
        node.id, ArrowType.current, node.endPosition,
        extras: e.offset));
  } on NodeNotFoundException catch (e) {
    logger.e('$actionType error ${e.message}');
    nodeContext.onCursor(EditingCursor(index, position));
  }
}

void arrowOnRightOrDown(ArrowType type, NodeContext nodeContext, Type actionType,
    BasicCursor cursor) {
  int index = -1;
  ArrowType t = type;
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
    nodeContext.onArrowAccept(
        AcceptArrowData(nodeContext.getNode(index).id, t, position));
  } on ArrowRightEndException catch (e) {
    logger.e('$actionType error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > nodeContext.nodeLength - 1) return;
    nodeContext.onArrowAccept(AcceptArrowData(nodeContext.getNode(nextIndex).id,
        ArrowType.current, nodeContext.getNode(nextIndex).beginPosition));
  } on ArrowDownBottomException catch (e) {
    logger.e('$actionType error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > nodeContext.nodeLength - 1) return;
    final node = nodeContext.getNode(nextIndex);
    nodeContext.onArrowAccept(AcceptArrowData(
        node.id, ArrowType.current, node.beginPosition,
        extras: e.offset));
  } on NodeNotFoundException catch (e) {
    logger.e('$actionType error ${e.message}');
    nodeContext.onCursor(EditingCursor(index, position));
  }
}
