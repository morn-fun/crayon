import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/events.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';

class BoldIntent extends Intent {
  const BoldIntent();
}

class BoldAction extends ContextAction<BoldIntent> {
  final EditorContext editorContext;

  BoldAction(this.editorContext);

  @override
  void invoke(BoldIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = editorContext.cursor;
    final controller = editorContext.controller;
    if(cursor is EditingCursor){
      editorContext.handleEventWhileEditing(EditingEvent(cursor, EventType.bold));
    } else if(cursor is SelectingNodeCursor){
      editorContext.handleEventWhileSelectingNode(SelectingNodeEvent(cursor, EventType.bold));
    } else if(cursor is SelectingNodesCursor){

    }
  }
}
