import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/controller.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../node/rich_text_node/rich_text_node.dart';

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

    } else if(cursor is SelectingNodeCursor){
      ///TODO:完善这里的hardcode


    } else if(cursor is SelectingNodesCursor){

    }
  }
}
