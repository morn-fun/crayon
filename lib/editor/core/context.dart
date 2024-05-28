import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide TableCell;
import '../command/modification.dart';
import '../cursor/cursor_generator.dart';

import '../command/basic.dart';
import '../cursor/basic.dart';
import '../exception/command.dart';
import '../node/basic.dart';
import '../node/table/table_cell.dart';
import 'command_invoker.dart';
import 'editor_controller.dart';
import 'entry_manager.dart';
import 'input_manager.dart';
import 'listener_collection.dart';
import 'logger.dart';

class EditorContext extends NodesOperator {
  final RichEditorController controller;
  final InputManager inputManager;
  final CommandInvoker invoker;
  final EntryManager entryManager;

  EditorContext(
      this.controller, this.inputManager, this.invoker, this.entryManager);

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
  void onEditingOffset(EditingOffset o) {
    final c = cursor;
    if (c is EditingCursor) {
      controller.setCursorOffset(CursorOffset(c.index, o));
    }
    final editingOff = o;
    final offset = editingOff.offset;
    if (kIsWeb) {
      inputManager.updateInputConnectionAttribute(InputConnectionAttribute(
          Rect.fromPoints(offset, offset.translate(0, editingOff.height)),
          Matrix4.translationValues(offset.dx, offset.dy, 0.0),
          Size(400, editingOff.height)));
    } else {
      inputManager.updateInputConnectionAttribute(InputConnectionAttribute(
          Rect.fromPoints(offset, offset.translate(0, editingOff.height)),
          Matrix4.translationValues(offset.dx, offset.dy, 0.0)
            ..translate(-offset.dx, -offset.dy),
          Size(400, editingOff.height)));
    }
  }

  void restartInput() => inputManager.restartInput();

  @override
  void onNode(EditorNode node, int index) {
    execute(ModifyNodeWithoutChangeCursor(index, node));
  }

  @override
  NodesOperator newOperator(
          List<EditorNode> nodes, BasicCursor<NodePosition> cursor) =>
      this;

  void removeEntry() => entryManager.removeEntry();
}

abstract class NodesOperator {
  EditorNode getNode(int index);

  BasicCursor get cursor;

  List<EditorNode> get nodes;

  Iterable<EditorNode> getRange(int begin, int end);

  void execute(BasicCommand command);

  void onCursor(BasicCursor cursor);

  void onPanUpdate(EditingCursor cursor);

  void onNode(EditorNode node, int index);

  void onEditingOffset(EditingOffset o);

  UpdateControllerOperation? update(Update data, {bool record = true});

  UpdateControllerOperation? replace(Replace data, {bool record = true});

  BasicCursor get selectAllCursor;

  ListenerCollection get listeners;

  NodesOperator newOperator(List<EditorNode> nodes, BasicCursor cursor);
}

class NodeBuildParam {
  final SingleNodeCursor? cursor;
  final int index;
  final dynamic extras;

  NodeBuildParam({this.cursor, required this.index, this.extras});

  NodeBuildParam.empty()
      : index = 0,
        cursor = null,
        extras = null;
}

class ActionOperator {
  final NodesOperator operator;
  final ValueGetter<BasicCursor> cursorGetter;

  BasicCursor get cursor => cursorGetter.call();

  ActionOperator(this.operator, this.cursorGetter);
}

class TableCellNodeContext extends NodesOperator {
  @override
  final BasicCursor cursor;
  final TableCell cell;
  final ValueChanged<Replace> onReplace;
  final ValueChanged<Update> onUpdate;
  final ValueChanged<BasicCursor> onBasicCursor;
  final ValueChanged<EditingOffset> editingOffset;
  final ValueChanged<EditingCursor> onPan;
  final ValueChanged<NodeWithIndex> onNodeUpdate;
  @override
  final ListenerCollection listeners;

  TableCellNodeContext({
    required this.cursor,
    required this.cell,
    required this.listeners,
    required this.onReplace,
    required this.onUpdate,
    required this.onBasicCursor,
    required this.editingOffset,
    required this.onPan,
    required this.onNodeUpdate,
  });

  final tag = 'TableCellNodeContext';

  @override
  void execute(BasicCommand command) {
    try {
      command.run(this);
    } catch (e) {
      logger.e('execute 【$command】error:$e');
    }
  }

  @override
  EditorNode getNode(int index) => cell.getNode(index);

  @override
  Iterable<EditorNode> getRange(int begin, int end) =>
      cell.nodes.getRange(begin, end);

  @override
  List<EditorNode> get nodes => cell.nodes;

  @override
  UpdateControllerOperation? replace(Replace data, {bool record = true}) {
    onReplace.call(data);
    return null;
  }

  @override
  BasicCursor<NodePosition> get selectAllCursor => cell.length == 1
      ? SelectingNodeCursor(0, cell.first.beginPosition, cell.first.endPosition)
      : SelectingNodesCursor(EditingCursor(0, cell.first.beginPosition),
          EditingCursor(cell.length - 1, cell.last.endPosition));

  @override
  UpdateControllerOperation? update(Update data, {bool record = true}) {
    onUpdate.call(data);
    return null;
  }

  @override
  void onCursor(BasicCursor cursor) => onBasicCursor.call(cursor);

  @override
  void onEditingOffset(EditingOffset o) => editingOffset.call(o);

  @override
  void onPanUpdate(EditingCursor cursor) => onPan(cursor);

  @override
  void onNode(EditorNode node, int index) =>
      onNodeUpdate.call(NodeWithIndex(node, index));

  @override
  NodesOperator newOperator(
          List<EditorNode> nodes, BasicCursor<NodePosition> cursor) =>
      TableCellNodeContext(
          cursor: cursor,
          cell: cell.copy(nodes: nodes),
          listeners: listeners,
          onReplace: onReplace,
          onUpdate: onUpdate,
          onBasicCursor: onBasicCursor,
          editingOffset: editingOffset,
          onPan: onPan,
          onNodeUpdate: onNodeUpdate);
}

class NodeWithIndex {
  final EditorNode node;
  final int index;

  NodeWithIndex(this.node, this.index);
}
