import 'dart:collection';

import 'package:flutter/material.dart';

import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';

class RichEditorController {
  RichEditorController.fromNodes(List<EditorNode> nodes) {
    _nodes.addAll(List.of(nodes));
  }

  final List<EditorNode> _nodes = [];
  BasicCursor _cursor = NoneCursor();

  final Set<ValueChanged<BasicCursor>> _cursorChangedCallbacks = {};
  final Set<VoidCallback> _nodesChangedCallbacks = {};
  final Map<String, Set<ValueChanged<EditorNode>>> _nodeChangedCallbacks = {};

  void addCursorChangedCallback(ValueChanged<BasicCursor> callback) =>
      _cursorChangedCallbacks.add(callback);

  void removeCursorChangedCallback(ValueChanged<BasicCursor> callback) =>
      _cursorChangedCallbacks.remove(callback);

  void addNodesChangedCallback(VoidCallback callback) =>
      _nodesChangedCallbacks.add(callback);

  void addNodeChangedCallback(String id, ValueChanged<EditorNode> callback) {
    final set = _nodeChangedCallbacks[id] ?? Set.identity();
    set.add(callback);
    _nodeChangedCallbacks[id] = set;
  }

  void removeNodeChangedCallback(String id, ValueChanged<EditorNode> callback) {
    final set = _nodeChangedCallbacks[id] ?? Set.identity();
    set.remove(callback);
    _nodeChangedCallbacks[id] = set;
  }

  EditorNode? getNode(int index) => _nodes[index];

  void update(UpdateData data) {
    _nodes[data.cursor.index] = data.node;
    _cursor = data.cursor;
    final set = Set.of(_nodeChangedCallbacks[data.node.id] ?? {});
    for (var c in set) {
      c.call(data.node);
    }
  }

  void replaceOne(ReplaceOneData data) {
    _nodes.removeAt(data.index);
    _nodes.insertAll(data.index, data.nodes);
    _cursor = data.cursor;
    for (var c in Set.of(_nodesChangedCallbacks)) {
      c.call();
    }
  }

  void replaceMore(ReplaceMoreData data) {
    _nodes.removeRange(data.start, data.end);
    _nodes.insertAll(data.start, data.nodes);
    _cursor = data.cursor;
    for (var c in Set.of(_nodesChangedCallbacks)) {
      c.call();
    }
  }

  void updateCursor(BasicCursor cursor) {
    _cursor = cursor;
    for (var c in Set.of(_cursorChangedCallbacks)) {
      c.call(cursor);
    }
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

class UpdateData {
  final EditorNode node;
  final EditingCursor cursor;

  UpdateData(this.node, this.cursor);
}

class ReplaceOneData {
  final int index;
  final List<EditorNode> nodes;
  final EditingCursor cursor;

  ReplaceOneData(this.index, this.nodes, this.cursor);
}

class ReplaceMoreData {
  final int start;
  final int end;
  final List<EditorNode> nodes;
  final BasicCursor cursor;

  ReplaceMoreData(this.start, this.end, this.nodes, this.cursor);
}
