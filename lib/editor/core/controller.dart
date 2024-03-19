import 'dart:collection';

import 'package:flutter/material.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import 'command_invoker.dart';
import 'logger.dart';

class RichEditorController {
  RichEditorController.fromNodes(List<EditorNode> nodes) {
    _nodes.addAll(List.of(nodes));
  }

  final _tag = 'RichEditorController';

  final List<EditorNode> _nodes = [];

  BasicCursor _cursor = NoneCursor();

  final Set<ValueChanged<BasicCursor>> _cursorChangedCallbacks = {};
  final Set<VoidCallback> _nodesChangedCallbacks = {};
  final Set<ValueChanged<Offset>> _onPanUpdateCallbacks = {};
  final Map<String, Set<ValueChanged<EditorNode>>> _nodeChangedCallbacks = {};

  void addCursorChangedCallback(ValueChanged<BasicCursor> callback) =>
      _cursorChangedCallbacks.add(callback);

  void removeCursorChangedCallback(ValueChanged<BasicCursor> callback) {
    _cursorChangedCallbacks.remove(callback);
    // logger.i(
    //     '$_tag, removeCursorChangedCallback length:${_cursorChangedCallbacks.length}');
  }

  void addNodesChangedCallback(VoidCallback callback) =>
      _nodesChangedCallbacks.add(callback);

  void addPanUpdateCallback(ValueChanged<Offset> callback) =>
      _onPanUpdateCallbacks.add(callback);

  void removePanUpdateCallback(ValueChanged<Offset> callback) =>
      _onPanUpdateCallbacks.remove(callback);

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

  EditorNode getNode(int index) => _nodes[index];

  UpdateControllerCommand? update(UpdateOne data, {bool record = true}) {
    final command = data.update(this);
    return record ? command : null;
  }

  UpdateControllerCommand? replace(Replace data, {bool record = true}) {
    final command = data.update(this);
    return record ? command : null;
  }

  void updateCursor(BasicCursor cursor, {bool notify = true}) {
    if (_cursor == cursor) return;
    _cursor = cursor;
    if (notify) notifyCursor(cursor);
  }

  void notifyCursor(BasicCursor cursor) {
    for (var c in Set.of(_cursorChangedCallbacks)) {
      c.call(cursor);
    }
    // logger.i('$_tag, notifyCursor length:${_cursorChangedCallbacks.length}');
  }

  void notifyDragUpdateDetails(Offset p) {
    for (var c in Set.of(_onPanUpdateCallbacks)) {
      c.call(p);
    }
    // logger.i(
    //     '$_tag, notifyDragUpdateDetails length:${_onPanUpdateCallbacks.length}');
  }

  void notifyNode(EditorNode node) {
    for (var c in Set.of(_nodeChangedCallbacks[node.id] ?? {})) {
      c.call(node);
    }
  }

  void notifyNodes() {
    for (var c in Set.of(_nodesChangedCallbacks)) {
      c.call();
    }
    // logger.i('$_tag, notifyNodes length:${_nodesChangedCallbacks.length}');
  }

  List<Map<String, dynamic>> toJson() => _nodes.map((e) => e.toJson()).toList();

  void dispose() {
    _nodes.clear();
    _cursorChangedCallbacks.clear();
    _nodesChangedCallbacks.clear();
    _nodeChangedCallbacks.clear();
  }

  UnmodifiableListView<EditorNode> get nodes => UnmodifiableListView(_nodes);

  BasicCursor get cursor => _cursor;
}

class UpdateOne implements UpdateControllerCommand {
  final int index;
  final EditorNode node;
  final BasicCursor cursor;

  UpdateOne(this.index, this.node, this.cursor);

  @override
  UpdateControllerCommand update(RichEditorController controller) {
    final nodes = controller._nodes;
    final undoCommand = UpdateOne(index, nodes[index], controller.cursor);
    nodes[index] = node;
    controller.updateCursor(cursor, notify: false);
    controller.notifyNode(node);
    controller.notifyCursor(cursor);
    return undoCommand;
  }
}

class Replace implements UpdateControllerCommand {
  final int begin;
  final int end;
  final UnmodifiableListView<EditorNode> newNodes;
  final BasicCursor cursor;

  Replace(this.begin, this.end, List<EditorNode> nodes, this.cursor)
      : newNodes = UnmodifiableListView(nodes);

  @override
  UpdateControllerCommand update(RichEditorController controller) {
    final nodes = controller._nodes;
    final oldNodes = nodes.sublist(begin, end);
    final command =
        Replace(begin, begin + newNodes.length, oldNodes, controller.cursor);
    nodes.replaceRange(begin, end, List.of(newNodes));
    controller.updateCursor(cursor, notify: false);
    controller.notifyNodes();
    controller.notifyCursor(cursor);
    return command;
  }
}
