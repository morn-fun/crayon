import 'package:flutter/material.dart';
import '../../editor/node/position_data.dart';

import '../command/basic_command.dart';
import '../command/modify.dart';
import '../cursor/basic_cursor.dart';
import '../exception/command_exception.dart';
import '../node/basic_node.dart';
import 'command_invoker.dart';
import 'editor_controller.dart';
import 'entry_manager.dart';
import 'input_manager.dart';
import 'listener_collection.dart';
import 'logger.dart';

class EditorContext {
  final RichEditorController controller;
  final InputManager inputManager;
  final FocusNode focusNode;
  final CommandInvoker invoker;
  final EntryManager entryManager;

  EditorContext(
    this.controller,
    this.inputManager,
    this.focusNode,
    this.invoker,
    this.entryManager,
  );

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
          .onEdit(EditingData(cursor.position, type, extras: extra));
      execute(ModifyNode(r.position.toCursor(cursor.index), r.node));
    } else if (cursor is SelectingNodeCursor) {
      final r = controller.getNode(cursor.index).onSelect(SelectingData(
          SelectingPosition(cursor.begin, cursor.end), type,
          extras: extra));
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

  EntryStatus get entryStatus => entryManager.status;

  void requestFocus() {
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  void updateInputConnectionAttribute(InputConnectionAttribute attribute) =>
      inputManager.updateInputConnectionAttribute(attribute);

  void updateStatus(ControllerStatus status) => controller.updateStatus(status);

  void updateEntryStatus(EntryStatus status) =>
      entryManager.updateStatus(status);

  void showOptionalMenu(Offset offset, OverlayState state) =>
      entryManager.showOptionalMenu(offset, state, this);

  void showTextMenu(OverlayState state, MenuInfo info, LayerLink link) =>
      entryManager.showTextMenu(state, info, link, this);

  void showLinkMenu(OverlayState state, MenuInfo info, LayerLink link,
          {UrlWithPosition? urlWithPosition}) =>
      entryManager.showLinkMenu(state, info, link, this,
          urlWithPosition: urlWithPosition);

  void hideMenu() {
    entryManager.hideMenu();
    inputManager.requestFocus();
  }
}
