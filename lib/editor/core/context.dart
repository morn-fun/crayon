import 'package:flutter/material.dart';

import '../command/basic_command.dart';
import '../cursor/basic_cursor.dart';
import '../exception/command_exception.dart';
import 'command_invoker.dart';
import 'controller.dart';
import 'events.dart';
import 'input_manager.dart';
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

  bool get typing => inputManager.typing;

  void handleEventWhileEditing(EditingEvent event) {
    final command =
        controller.getNode(event.cursor.index).handleEventWhileEditing(event);
    if (command != null) invoker.execute(command, controller);
  }

  void handleEventWhileSelectingNode(SelectingNodeEvent event) {
    final command =
        controller.getNode(event.cursor.index).handleEventWhileSelecting(event);
    if (command != null) invoker.execute(command, controller);
  }

  void requestFocus() {
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }
}
