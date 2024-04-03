import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../command/modification.dart';
import '../command/replacement.dart';
import '../command/selecting_nodes/deletion.dart';
import '../core/context.dart';
import '../core/controller.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import '../node/basic_node.dart';
import '../node/position_data.dart';

class CopyIntent extends Intent {
  const CopyIntent();
}

class CopyAction extends ContextAction<CopyIntent> {
  final EditorContext editorContext;

  CopyAction(this.editorContext);

  @override
  void invoke(CopyIntent intent, [BuildContext? context]) async{
    logger.i('$runtimeType is invoking!');
    final cursor = editorContext.cursor;
    if(cursor is EditingCursor) return;
    final controller = editorContext.controller;
    if(cursor is SelectingNodeCursor){

    } else if(cursor is SelectingNodesCursor){

    }
  }
}