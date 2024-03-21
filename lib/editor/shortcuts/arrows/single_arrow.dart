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
    controller.onArrowAccept(index, t, position);
  } on ArrowIsEndException catch (e) {
    logger.e('$actionType error $e');
    final lastIndex = index - 1;
    if (lastIndex < 0) return;
    controller.onArrowAccept(lastIndex, ArrowType.current,
        controller.getNode(lastIndex).endPosition);
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
    controller.onArrowAccept(index, t, position);
  } on ArrowIsEndException catch (e) {
    logger.e('$actionType error $e');
    final nextIndex = index + 1;
    final nodes = controller.nodes;
    if (nextIndex > nodes.length - 1) return;
    controller.onArrowAccept(nextIndex, ArrowType.current,
        controller.getNode(nextIndex).beginPosition);
  }
}
