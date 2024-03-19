import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';

class LeftArrowIntent extends Intent {
  const LeftArrowIntent();
}

class RightArrowIntent extends Intent {
  const RightArrowIntent();
}

class UpArrowIntent extends Intent {
  const UpArrowIntent();
}

class DownArrowIntent extends Intent {
  const DownArrowIntent();
}

enum ArrowType {
  current,
  left,
  right,
  up,
  down,
  selectionLeft,
  selectionRight,
  selectionUp,
  selectionDown,
  moveToNextWorldLeft,
  moveToNextWorldRight,
  moveToNextWorldUp,
  moveToNextWorldDown,
}

typedef ArrowDelegate = void Function(ArrowType type, NodePosition position);

class LeftArrowAction extends ContextAction<LeftArrowIntent> {
  final EditorContext editorContext;

  LeftArrowAction(this.editorContext);

  @override
  void invoke(LeftArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = editorContext.cursor;
    final controller = editorContext.controller;
    int index = -1;
    late NodePosition position;
    ArrowType type = ArrowType.left;
    if (cursor is EditingCursor) {
      index = cursor.index;
      position = cursor.position;
    } else if (cursor is SelectingNodeCursor) {
      index = cursor.index;
      position = cursor.left;
      type = ArrowType.current;
    } else if (cursor is SelectingNodesCursor) {
      index = cursor.left.index;
      position = cursor.left.position;
      type = ArrowType.current;
    }
    if (index == -1) return;
    try {
      controller.onArrowAccept(index, type, position);
    } on ArrowIsEndException catch (e) {
      logger.e('$runtimeType error $e');
      final lastIndex = index - 1;
      if (lastIndex < 0) return;
      controller.onArrowAccept(lastIndex, ArrowType.current,
          controller.getNode(lastIndex).endPosition);
    }
  }
}

class RightArrowAction extends ContextAction<RightArrowIntent> {
  final EditorContext editorContext;

  RightArrowAction(this.editorContext);

  @override
  void invoke(RightArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = editorContext.cursor;
    final controller = editorContext.controller;
    int index = -1;
    ArrowType type = ArrowType.right;
    late NodePosition position;
    if (cursor is EditingCursor) {
      index = cursor.index;
      position = cursor.position;
    } else if (cursor is SelectingNodeCursor) {
      index = cursor.index;
      position = cursor.right;
      type = ArrowType.current;
    } else if (cursor is SelectingNodesCursor) {
      index = cursor.right.index;
      position = cursor.right.position;
      type = ArrowType.current;
    }
    if (index == -1) return;
    try {
      controller.onArrowAccept(index, type, position);
    } on ArrowIsEndException catch (e) {
      logger.e('$runtimeType error $e');
      final nextIndex = index + 1;
      final nodes = controller.nodes;
      if (nextIndex > nodes.length - 1) return;
      controller.onArrowAccept(nextIndex, ArrowType.current,
          controller.getNode(nextIndex).beginPosition);
    }
  }
}

class UpArrowAction extends ContextAction<UpArrowIntent> {
  final EditorContext editorContext;

  UpArrowAction(this.editorContext);

  @override
  void invoke(UpArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    throw UnimplementedError();
  }
}

class DownArrowAction extends ContextAction<DownArrowIntent> {
  final EditorContext editorContext;

  DownArrowAction(this.editorContext);

  @override
  void invoke(DownArrowIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    throw UnimplementedError();
  }
}
