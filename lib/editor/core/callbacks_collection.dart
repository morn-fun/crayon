import 'package:flutter/material.dart';

import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import '../shortcuts/arrows.dart';
import 'logger.dart';

class CallbackCollection {
  final tag = 'CallbackCollection';

  final Set<ValueChanged<BasicCursor>> _cursorChangedCallbacks = {};
  final Set<VoidCallback> _nodesChangedCallbacks = {};
  final Set<ValueChanged<Offset>> _onPanUpdateCallbacks = {};
  final Map<String, Set<ValueChanged<EditorNode>>> _nodeChangedCallbacks = {};
  final Map<String, Set<ArrowDelegate>> _arrowDelegates = {};
  final Map<String, Set<ValueChanged<Offset>>> _onTapDownCallbacks = {};

  void dispose() {
    logger.i('$tag, dispose');
    _cursorChangedCallbacks.clear();
    _nodesChangedCallbacks.clear();
    _onPanUpdateCallbacks.clear();
    _onTapDownCallbacks.clear();
    _nodeChangedCallbacks.clear();
    _arrowDelegates.clear();
  }

  void addCursorChangedCallback(ValueChanged<BasicCursor> callback) =>
      _cursorChangedCallbacks.add(callback);

  void removeCursorChangedCallback(ValueChanged<BasicCursor> callback) {
    _cursorChangedCallbacks.remove(callback);
    logger.i(
        '$tag, removeCursorChangedCallback length:${_cursorChangedCallbacks.length}');
  }

  void addNodesChangedCallback(VoidCallback callback) =>
      _nodesChangedCallbacks.add(callback);

  void addPanUpdateCallback(ValueChanged<Offset> callback) =>
      _onPanUpdateCallbacks.add(callback);

  void removePanUpdateCallback(ValueChanged<Offset> callback) =>
      _onPanUpdateCallbacks.remove(callback);

  void addTapDownCallback(String id, ValueChanged<Offset> callback) {
    logger.i('$tag, addTapDownCallback:$id');
    final set = _onTapDownCallbacks[id] ?? {};
    set.add(callback);
    _onTapDownCallbacks[id] = set;
  }

  void removeTapDownCallback(String id, ValueChanged<Offset> callback) {
    final set = _onTapDownCallbacks[id] ?? {};
    set.remove(callback);
    logger.i('$tag, removeTapDownCallback:$id, length:${set.length}');
    if (set.isEmpty) {
      _onTapDownCallbacks.remove(id);
    } else {
      _onTapDownCallbacks[id] = set;
    }
  }

  void addNodeChangedCallback(String id, ValueChanged<EditorNode> callback) {
    logger.i('$tag, addNodeChangedCallback:$id');
    final set = _nodeChangedCallbacks[id] ?? {};
    set.add(callback);
    _nodeChangedCallbacks[id] = set;
  }

  void removeNodeChangedCallback(String id, ValueChanged<EditorNode> callback) {
    final set = _nodeChangedCallbacks[id] ?? {};
    set.remove(callback);
    logger.i('$tag, removeNodeChangedCallback:$id, length:${set.length}');
    if (set.isEmpty) {
      _nodeChangedCallbacks.remove(id);
    } else {
      _nodeChangedCallbacks[id] = set;
    }
  }

  void addArrowDelegate(String id, ArrowDelegate callback) {
    logger.i('$tag, addArrowDelegate:$id');
    final set = _arrowDelegates[id] ?? {};
    set.add(callback);
    _arrowDelegates[id] = set;
  }

  void removeArrowDelegate(String id, ArrowDelegate callback) {
    final set = _arrowDelegates[id] ?? {};
    set.remove(callback);
    logger.i('$tag, addArrowDelegate:$id, length:${set.length}');
    if (set.isEmpty) {
      _arrowDelegates.remove(id);
    } else {
      _arrowDelegates[id] = set;
    }
  }

  void onArrowAccept(String id, ArrowType type, NodePosition position) {
    final set = _arrowDelegates[id] ?? {};
    logger.i('$tag, onArrowAccept, id:$id, type:$type, length:${set.length}');
    for (var c in Set.of(set)) {
      c.call(type, position);
    }
  }

  void notifyCursor(BasicCursor cursor) {
    for (var c in Set.of(_cursorChangedCallbacks)) {
      c.call(cursor);
    }
    logger.i('$tag, notifyCursor length:${_cursorChangedCallbacks.length}');
  }

  void notifyDragUpdateDetails(Offset p) {
    for (var c in Set.of(_onPanUpdateCallbacks)) {
      c.call(p);
    }
    logger.i(
        '$tag, notifyDragUpdateDetails length:${_onPanUpdateCallbacks.length}');
  }

  void notifyTapDown(String id, Offset p) {
    for (var c in Set.of(_onTapDownCallbacks[id] ?? {})) {
      c.call(p);
    }
    logger.i('$tag, notifyTapDown length:${_onTapDownCallbacks[id]?.length}');
  }

  void notifyNode(EditorNode node) {
    for (var c in Set.of(_nodeChangedCallbacks[node.id] ?? {})) {
      c.call(node);
    }
    logger
        .i('$tag, notifyNode length:${_nodeChangedCallbacks[node.id]?.length}');
  }

  void notifyNodes() {
    for (var c in Set.of(_nodesChangedCallbacks)) {
      c.call();
    }
    logger.i('$tag, notifyNodes length:${_nodesChangedCallbacks.length}');
  }
}
