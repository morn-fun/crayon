import 'package:flutter/material.dart';
import '../cursor/cursor_generator.dart';
import '../cursor/node_position.dart';

import '../command/basic.dart';
import '../cursor/basic.dart';
import '../exception/command.dart';
import '../node/basic.dart';
import 'command_invoker.dart';
import 'editor_controller.dart';
import 'entry_manager.dart';
import 'input_manager.dart';
import 'listener_collection.dart';
import 'logger.dart';

class EditorContext extends NodeContext {
  final RichEditorController controller;
  final InputManager inputManager;
  final FocusNode focusNode;
  final CommandInvoker invoker;
  final EntryManager entryManager;

  EditorContext(this.controller, this.inputManager, this.focusNode,
      this.invoker, this.entryManager);

  @override
  void execute(BasicCommand command) {
    try {
      invoker.execute(command, this);
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

  @override
  BasicCursor get cursor => controller.cursor;

  @override
  ListenerCollection get listeners => controller.listeners;

  void requestFocus() {
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  @override
  EditorNode getNode(int index) => controller.getNode(index);

  int get nodeLength => controller.nodeLength;

  @override
  List<EditorNode> get nodes => controller.nodes;

  @override
  Iterable<EditorNode> getRange(int begin, int end) =>
      controller.getRange(begin, end);

  void updateCursor(BasicCursor cursor, {bool notify = true}) =>
      controller.updateCursor(cursor, notify: notify);

  @override
  BasicCursor<NodePosition> get selectAllCursor => controller.selectAllCursor;

  @override
  UpdateControllerOperation? update(Update data, {bool record = true}) =>
      controller.update(data, record: record);

  @override
  UpdateControllerOperation? replace(Replace data, {bool record = true}) =>
      controller.replace(data, record: record);

  @override
  NodeContext? getChildContext(String id) {
    final set = _id2ContextMap[id];
    if (set == null || set.isEmpty) return null;
    return set.first;
  }

  @override
  void addContext(String id, NodeContext context) {
    var set = _id2ContextMap[id];
    set ??= {};
    set.add(context);
    _id2ContextMap[id] = set;
  }

  @override
  void removeContext(String id, NodeContext context) {
    var set = _id2ContextMap[id];
    set ??= {};
    set.remove(id);
    if (set.isEmpty) {
      _id2ContextMap.remove(id);
    } else {
      _id2ContextMap[id] = set;
    }
  }

  @override
  void onCursor(BasicCursor cursor) {
    controller.updateCursor(cursor);
  }

  @override
  void onPanUpdate(EditingCursor cursor) {
    final c = generateSelectingCursor(
        cursor, controller.panStartCursor, (i) => controller.getNode(i));
    if (c != null) controller.updateCursor(c);
  }

  @override
  void onCursorOffset(CursorOffset o) {
    controller.setCursorOffset(o);
    final editingOff = o.offset;
    final offset = editingOff.offset;
    inputManager.updateInputConnectionAttribute(InputConnectionAttribute(
        Rect.fromPoints(
            offset, editingOff.offset.translate(0, editingOff.height)),
        Matrix4.translationValues(offset.dx, offset.dy, 0.0)
          ..translate(-offset.dx, -offset.dy),
        Size(400, editingOff.height)));
  }
}

abstract class NodeContext {
  EditorNode getNode(int index);

  BasicCursor get cursor;

  List<EditorNode> get nodes;

  Iterable<EditorNode> getRange(int begin, int end);

  void execute(BasicCommand command);

  void onCursor(BasicCursor cursor);

  void onPanUpdate(EditingCursor cursor);

  void onCursorOffset(CursorOffset o);

  UpdateControllerOperation? update(Update data, {bool record = true});

  UpdateControllerOperation? replace(Replace data, {bool record = true});

  BasicCursor get selectAllCursor;

  ListenerCollection get listeners;

  final Map<String, Set<NodeContext>> _id2ContextMap = {};

  NodeContext? getChildContext(String id) {
    final set = _id2ContextMap[id];
    if (set == null || set.isEmpty) return null;
    return set.first;
  }

  void addContext(String id, NodeContext context) {
    var set = _id2ContextMap[id];
    set ??= {};
    set.add(context);
    _id2ContextMap[id] = set;
  }

  void removeContext(String id, NodeContext context) {
    var set = _id2ContextMap[id];
    set ??= {};
    set.remove(context);
    if (set.isEmpty) {
      _id2ContextMap.remove(id);
    } else {
      _id2ContextMap[id] = set;
    }
  }
}

class NodeBuildParam {
  final SingleNodePosition? position;
  final int index;
  final dynamic extras;

  NodeBuildParam({this.position, required this.index, this.extras});

  NodeBuildParam.empty()
      : index = 0,
        position = null,
        extras = null;
}

class ActionContext {
  final NodeContext context;
  final ValueGetter<BasicCursor> cursorGetter;

  BasicCursor get cursor => cursorGetter.call();

  ActionContext(this.context, this.cursorGetter);
}
