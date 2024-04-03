import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../core/logger.dart';
import '../../cursor/basic_cursor.dart';
import '../../exception/editor_node_exception.dart';
import 'arrows.dart';

class LeftArrowAction extends ContextAction<LeftArrowIntent> {
  final EditorContext editorContext;

  LeftArrowAction(this.editorContext);

  @override
  void invoke(LeftArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    _onLeftOrUp(ArrowType.left, editorContext, runtimeType);
  }
}

class RightArrowAction extends ContextAction<RightArrowIntent> {
  final EditorContext editorContext;

  RightArrowAction(this.editorContext);

  @override
  void invoke(RightArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    _onRightOrDown(ArrowType.right, editorContext, runtimeType);
  }
}

class UpArrowAction extends ContextAction<UpArrowIntent> {
  final EditorContext editorContext;

  UpArrowAction(this.editorContext);

  @override
  void invoke(UpArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    _onLeftOrUp(ArrowType.up, editorContext, runtimeType);
  }
}

class DownArrowAction extends ContextAction<DownArrowIntent> {
  final EditorContext editorContext;

  DownArrowAction(this.editorContext);

  @override
  void invoke(DownArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    _onRightOrDown(ArrowType.down, editorContext, runtimeType);
  }
}

void _onLeftOrUp(ArrowType type, EditorContext editorContext, Type actionType) {
  final cursor = editorContext.cursor;
  final controller = editorContext.controller;
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
    controller.onArrowAccept(
        AcceptArrowData(controller.getNode(index).id, t, position));
  } on ArrowLeftBeginException catch (e) {
    logger.e('$actionType error ${e.message}');
    final lastIndex = index - 1;
    if (lastIndex < 0) return;
    controller.onArrowAccept(AcceptArrowData(controller.getNode(lastIndex).id,
        ArrowType.current, controller.getNode(lastIndex).endPosition));
  } on ArrowUpTopException catch (e) {
    logger.e('$actionType error ${e.message}');
    final lastIndex = index - 1;
    if (lastIndex < 0) return;
    final node = controller.getNode(lastIndex);
    controller.onArrowAccept(AcceptArrowData(
        node.id, ArrowType.current, node.endPosition,
        extras: e.offset));
  }
}

void _onRightOrDown(
    ArrowType type, EditorContext editorContext, Type actionType) {
  final cursor = editorContext.cursor;
  final controller = editorContext.controller;
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
    controller.onArrowAccept(
        AcceptArrowData(controller.getNode(index).id, t, position));
  } on ArrowRightEndException catch (e) {
    logger.e('$actionType error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > controller.nodeLength - 1) return;
    controller.onArrowAccept(AcceptArrowData(controller.getNode(nextIndex).id,
        ArrowType.current, controller.getNode(nextIndex).beginPosition));
  } on ArrowDownBottomException catch (e) {
    logger.e('$actionType error ${e.message}');
    final nextIndex = index + 1;
    if (nextIndex > controller.nodeLength - 1) return;
    final node = controller.getNode(nextIndex);
    controller.onArrowAccept(AcceptArrowData(
        node.id, ArrowType.current, node.beginPosition,
        extras: e.offset));
  }
}
