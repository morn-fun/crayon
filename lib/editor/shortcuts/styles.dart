import 'package:flutter/material.dart';

import '../command/selecting_nodes/update.dart';
import '../core/context.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';

class UnderlineIntent extends Intent {
  const UnderlineIntent();
}

class BoldIntent extends Intent {
  const BoldIntent();
}

class ItalicIntent extends Intent {
  const ItalicIntent();
}

class LineThroughIntent extends Intent {
  const LineThroughIntent();
}

class UnderlineAction extends ContextAction<UnderlineIntent> {
  final EditorContext editorContext;

  UnderlineAction(this.editorContext);

  @override
  void invoke(UnderlineIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    _onEvent(editorContext, EventType.underline);
  }
}

class BoldAction extends ContextAction<BoldIntent> {
  final EditorContext editorContext;

  BoldAction(this.editorContext);

  @override
  void invoke(BoldIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    _onEvent(editorContext, EventType.bold);
  }
}

class ItalicAction extends ContextAction<ItalicIntent> {
  final EditorContext editorContext;

  ItalicAction(this.editorContext);

  @override
  void invoke(ItalicIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    _onEvent(editorContext, EventType.italic);
  }
}

class LineThroughAction extends ContextAction<LineThroughIntent> {
  final EditorContext editorContext;

  LineThroughAction(this.editorContext);

  @override
  void invoke(LineThroughIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    _onEvent(editorContext, EventType.lineThrough);
  }
}

void _onEvent(EditorContext context, EventType type) {
  final c = context.cursor;
  if (c is SingleNodeCursor) {
    context.onNodeEditing(c, type);
  } else if (c is SelectingNodesCursor) {
    context.execute(UpdateSelectingNodes(c, type));
  }
}
