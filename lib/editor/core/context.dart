import 'package:flutter/material.dart';
import '../../editor/node/position_data.dart';

import '../command/basic_command.dart';
import '../command/modify.dart';
import '../cursor/basic_cursor.dart';
import '../exception/command_exception.dart';
import '../node/basic_node.dart';
import 'command_invoker.dart';
import 'controller.dart';
import 'input_manager.dart';
import 'listener_collection.dart';
import 'logger.dart';

class EditorContext {
  final RichEditorController controller;
  final InputManager inputManager;
  final FocusNode focusNode;
  final CommandInvoker invoker;

  EditorContext(
      this.controller, this.inputManager, this.focusNode, this.invoker);

  void execute(BasicCommand command) {
    try {
      invoker.execute(command, controller);
    } on PerformCommandException catch (e) {
      logger.e('$e');
    }
  }

  void onNodeEditing(SingleNodeCursor cursor, EventType type, {dynamic extra}) {
    if (cursor is EditingCursor) {
      final r = controller
          .getNode(cursor.index)
          .onEdit(EditingData(cursor.position, type));
      execute(ModifyNode(r.position.toCursor(cursor.index), r.node));
    } else if (cursor is SelectingNodeCursor) {
      final r = controller.getNode(cursor.index).onSelect(
          SelectingData(SelectingPosition(cursor.begin, cursor.end), type));
      execute(ModifyNode(r.position.toCursor(cursor.index), r.node));
    }
  }

  void undo() {
    try {
      invoker.undo(controller);
    } on PerformCommandException catch (e) {
      logger.e('undo $e');
    }
  }

  void redo() {
    try {
      invoker.redo(controller);
    } on PerformCommandException catch (e) {
      logger.e('redo $e');
    }
  }

  BasicCursor get cursor => controller.cursor;

  ListenerCollection get listeners => controller.listeners;

  void requestFocus() {
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  void updateStatus(ControllerStatus status) => controller.updateStatus(status);
}
