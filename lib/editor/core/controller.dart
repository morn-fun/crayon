import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:pre_editor/editor/node/rich_text_node/rich_text_node.dart';

import '../command/basic_command.dart';
import '../cursor/basic_cursor.dart';
import '../exception/command_exception.dart';
import '../node/basic_node.dart';
import 'logger.dart';

class RichEditorController {
  RichEditorController.fromNodes(List<EditorNode> nodes) {
    _nodes.addAll(List.of(nodes));
  }

  final _tag = 'RichEditorController';

  final List<EditorNode> _nodes = [];
  final List<UndoCommand> _undoCommands = [];
  final List<UpdateCommand> _redoCommands = [];
  BasicCursor _cursor = NoneCursor();

  final Set<ValueChanged<BasicCursor>> _cursorChangedCallbacks = {};
  final Set<VoidCallback> _nodesChangedCallbacks = {};
  final Map<String, Set<ValueChanged<EditorNode>>> _nodeChangedCallbacks = {};

  void addCursorChangedCallback(ValueChanged<BasicCursor> callback) =>
      _cursorChangedCallbacks.add(callback);

  void removeCursorChangedCallback(ValueChanged<BasicCursor> callback) {
    _cursorChangedCallbacks.remove(callback);
    // logger.i('$_tag, removeCursorChangedCallback length:${_cursorChangedCallbacks.length}');
  }

  void addNodesChangedCallback(VoidCallback callback) =>
      _nodesChangedCallbacks.add(callback);

  void addNodeChangedCallback(String id, ValueChanged<EditorNode> callback) {
    // logger.i('$_tag, addNodeChangedCallback:$id');
    final set = _nodeChangedCallbacks[id] ?? {};
    set.add(callback);
    _nodeChangedCallbacks[id] = set;
  }

  void removeNodeChangedCallback(String id, ValueChanged<EditorNode> callback) {
    final set = _nodeChangedCallbacks[id] ?? {};
    set.remove(callback);
    // logger.i('$_tag, removeNodeChangedCallback:$id, length:${set.length}');
    if (set.isEmpty) {
      _nodeChangedCallbacks.remove(id);
    } else {
      _nodeChangedCallbacks[id] = set;
    }
  }

  EditorNode? getNode(int index) => _nodes[index];

  void execute(BasicCommand command) {
    try {
      logger.i('execute 【${command.runtimeType}】');
      command.run(this);
      _redoCommands.clear();
    } catch (e) {
      throw PerformCommandException(command.runtimeType, e);
    }
  }

  void undo() {
    if (_undoCommands.isEmpty) throw NoCommandException('undo');
    final command = _undoCommands.removeLast();
    logger.i('undo 【${command.runtimeType}】');
    try {
      final redoCommand = command.undo(this);
      _redoCommands.add(redoCommand);
    } catch (e) {
      throw PerformCommandException(command.runtimeType, e);
    }
  }

  void redo() {
    if (_redoCommands.isEmpty) throw NoCommandException('undo');
    final command = _redoCommands.removeLast();
    logger.i('redo 【${command.runtimeType}】');
    try {
      final undoCommand = command.update(this);
      _undoCommands.add(undoCommand);
    } catch (e) {
      throw PerformCommandException(command.runtimeType, e);
    }
  }

  void update(UpdateOne data, {bool record = true}) =>
      _insertUndoCommand(data, record);

  void replace(Replace data, {bool record = true}) =>
      _insertUndoCommand(data, record);

  void _insertUndoCommand(UpdateCommand data, bool record) {
    final command = data.update(this);
    if (record) _undoCommands.add(command);
  }

  void updateCursor(BasicCursor cursor) {
    final command = _updateCursor(cursor);
    if (command != null) _undoCommands.add(command);
  }

  UndoCommand? _updateCursor(BasicCursor cursor) {
    if (_cursor == cursor) return null;
    final command = UndoUpdateCursor(_cursor);
    _cursor = cursor;
    notifyCursor(cursor);
    return command;
  }

  void notifyCursor(BasicCursor cursor) {
    for (var c in Set.of(_cursorChangedCallbacks)) {
      c.call(cursor);
    }
  }

  void notifyNode(EditorNode node) {
    for (var c in Set.of(_nodeChangedCallbacks[node.id] ?? {})) {
      c.call(node);
    }
  }

  void notifyAll() {
    for (var c in Set.of(_nodesChangedCallbacks)) {
      c.call();
    }
  }

  List<Map<String, dynamic>> toJson() => _nodes.map((e) => e.toJson()).toList();

  void dispose() {
    _nodes.clear();
    _cursorChangedCallbacks.clear();
    _nodesChangedCallbacks.clear();
    _nodeChangedCallbacks.clear();
    _undoCommands.clear();
    _redoCommands.clear();
  }

  UnmodifiableListView<EditorNode> get nodes => UnmodifiableListView(_nodes);

  BasicCursor get cursor => _cursor;
}

abstract class UndoCommand {
  UpdateCommand undo(RichEditorController controller);
}

abstract class UpdateCommand {
  UndoCommand update(RichEditorController controller);
}

class UpdateCursor implements UpdateCommand {
  final BasicCursor cursor;

  UpdateCursor(this.cursor);

  @override
  UndoCommand update(RichEditorController controller) {
    final command = UndoUpdateCursor(controller.cursor);
    controller._updateCursor(cursor);
    return command;
  }
}

class UndoUpdateCursor implements UndoCommand {
  final BasicCursor cursor;

  UndoUpdateCursor(this.cursor);

  @override
  UpdateCommand undo(RichEditorController controller) {
    final command = UpdateCursor(controller.cursor);
    controller._updateCursor(cursor);
    return command;
  }
}

class UpdateOne implements UpdateCommand {
  final EditorNode node;
  final BasicCursor cursor;
  final int index;

  UpdateOne(this.node, this.cursor, this.index);

  @override
  UndoCommand update(RichEditorController controller) {
    final nodes = controller._nodes;
    final undoCommand = UndoUpdateOne(nodes[index], controller.cursor, index);
    nodes[index] = node;
    controller.notifyNode(node);
    controller._updateCursor(cursor);
    return undoCommand;
  }
}

class UndoUpdateOne implements UndoCommand {
  final EditorNode node;
  final BasicCursor cursor;
  final int index;

  UndoUpdateOne(this.node, this.cursor, this.index);

  @override
  UpdateCommand undo(RichEditorController controller) {
    final nodes = controller._nodes;
    final command = UpdateOne(nodes[index], controller.cursor, index);
    nodes[index] = node;
    controller.notifyNode(node);
    controller._updateCursor(cursor);
    return command;
  }
}

class Replace implements UpdateCommand {
  final int begin;
  final int end;
  final UnmodifiableListView<EditorNode> newNodes;
  final BasicCursor cursor;

  Replace(this.begin, this.end, List<EditorNode> nodes, this.cursor)
      : newNodes = UnmodifiableListView(nodes);

  @override
  UndoCommand update(RichEditorController controller) {
    final nodes = controller._nodes;
    final oldNodes = nodes.sublist(begin, end);
    final command = UndoReplace(
        begin, begin + newNodes.length, oldNodes, controller.cursor);
    nodes.replaceRange(begin, end, List.of(newNodes));
    controller.notifyAll();
    controller._updateCursor(cursor);
    return command;
  }
}

class UndoReplace implements UndoCommand {
  final int begin;
  final int end;
  final UnmodifiableListView<EditorNode> oldNodes;
  final BasicCursor cursor;

  UndoReplace(this.begin, this.end, List<EditorNode> nodes, this.cursor)
      : oldNodes = UnmodifiableListView(nodes);

  @override
  UpdateCommand undo(RichEditorController controller) {
    final nodes = controller._nodes;
    final newNodes = nodes.sublist(begin, end);
    final command =
        Replace(begin, begin + oldNodes.length, newNodes, controller.cursor);
    nodes.replaceRange(begin, end, List.of(oldNodes));
    controller.notifyAll();
    controller._updateCursor(cursor);
    return command;
  }
}
