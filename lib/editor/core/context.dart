import 'package:flutter/material.dart';
import '../cursor/node_position.dart';

import '../command/basic.dart';
import '../command/modification.dart';
import '../cursor/basic.dart';
import '../exception/command.dart';
import '../node/basic.dart';
import '../shortcuts/arrows/arrows.dart';
import 'command_invoker.dart';
import 'editor_controller.dart';
import 'entry_manager.dart';
import 'input_manager.dart';
import 'listener_collection.dart';
import 'logger.dart';

class EditorContext implements NodeContext {
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

  @override
  void execute(BasicCommand command) {
    try {
      invoker.execute(command, this);
    } on PerformCommandException catch (e) {
      logger.e('$e');
    }
  }

  @override
  void onNodeEditing(SingleNodeCursor cursor, EventType type, {dynamic extra}) {
    if (cursor is EditingCursor) {
      final r = controller
          .getNode(cursor.index)
          .onEdit(EditingData(cursor.position, type, listeners, extras: extra));
      execute(ModifyNode(r.position.toCursor(cursor.index), r.node));
    } else if (cursor is SelectingNodeCursor) {
      final r = controller.getNode(cursor.index).onSelect(SelectingData(
          SelectingPosition(cursor.begin, cursor.end), type, listeners,
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

  @override
  BasicCursor get cursor => controller.cursor;

  @override
  ListenerCollection get listeners => controller.listeners;

  void requestFocus() {
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  void updateInputConnectionAttribute(InputConnectionAttribute attribute) =>
      inputManager.updateInputConnectionAttribute(attribute);

  void updateStatus(ControllerStatus status) => controller.updateStatus(status);

  void showOptionalMenu(EditingOffset offset, OverlayState state) =>
      entryManager.showOptionalMenu(offset, state, this);

  void showTextMenu(OverlayState state, MenuInfo info, LayerLink link) =>
      entryManager.showTextMenu(state, info, link, this);

  void showLinkMenu(OverlayState state, MenuInfo info, LayerLink link,
          {UrlWithPosition? urlWithPosition}) =>
      entryManager.showLinkMenu(state, info, link, this,
          urlWithPosition: urlWithPosition);

  @override
  void hideMenu() {
    entryManager.removeEntry();
    inputManager.requestFocus();
  }

  @override
  EditorNode getNode(int index) => controller.getNode(index);

  @override
  int get nodeLength => controller.nodeLength;

  @override
  List<EditorNode> get nodes => controller.nodes;

  @override
  Iterable<EditorNode> getRange(int begin, int end) =>
      controller.getRange(begin, end);

  @override
  void updateCursor(BasicCursor cursor, {bool notify = true}) =>
      controller.updateCursor(cursor, notify: notify);

  @override
  BasicCursor<NodePosition> get selectAllCursor => controller.selectAllCursor;

  @override
  void onArrowAccept(AcceptArrowData data) => controller.onArrowAccept(data);

  @override
  UpdateControllerOperation? update(Update data, {bool record = true}) =>
      controller.update(data, record: record);

  @override
  UpdateControllerOperation? replace(Replace data, {bool record = true}) =>
      controller.replace(data, record: record);
}

abstract class NodeContext {
  EditorNode getNode(int index);

  BasicCursor get cursor;

  List<EditorNode> get nodes;

  Iterable<EditorNode> getRange(int begin, int end);

  void execute(BasicCommand command);

  int get nodeLength => nodes.length;

  void onNodeEditing(SingleNodeCursor cursor, EventType type, {dynamic extra});

  void updateCursor(BasicCursor cursor, {bool notify = true});

  BasicCursor get selectAllCursor;

  void onArrowAccept(AcceptArrowData data) => listeners.onArrowAccept(data);

  UpdateControllerOperation? update(Update data, {bool record = true});

  UpdateControllerOperation? replace(Replace data, {bool record = true});

  ListenerCollection get listeners;

  void hideMenu();
}
