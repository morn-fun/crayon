import 'package:flutter/material.dart';

import '../cursor/basic.dart';
import '../exception/editor_node.dart';
import '../node/basic.dart';
import '../shortcuts/arrows/arrows.dart';
import '../widget/menu/optional.dart';
import 'editor_controller.dart';
import 'logger.dart';

class ListenerCollection {
  final tag = 'ListenerCollection';

  final Set<ValueChanged<BasicCursor>> _cursorListeners = {};
  final Set<ValueChanged<List<EditorNode>>> _nodesListeners = {};
  final Map<String, Set<GestureStateListener>> _gestureListeners = {};
  final Map<String, Set<ValueChanged<EditorNode>>> _nodeListeners = {};
  final Map<String, Set<ArrowDelegate>> _arrowDelegates = {};
  final Set<ValueChanged<OptionalSelectedType>> _menuListeners = {};
  final Map<String, Set<ListenerCollection>> _id2Listeners = {};

  ListenerCollection({
    Set<ValueChanged<BasicCursor>>? cursorListeners,
    Set<ValueChanged<List<EditorNode>>>? nodesListeners,
    Map<String, Set<GestureStateListener>>? gestureListeners,
    Map<String, Set<ValueChanged<EditorNode>>>? nodeListeners,
    Map<String, Set<ArrowDelegate>>? arrowDelegates,
    Set<ValueChanged<OptionalSelectedType>>? optionalMenuListeners,
  }) {
    _cursorListeners.addAll(cursorListeners ?? {});
    _nodesListeners.addAll(nodesListeners ?? {});
    _gestureListeners.addAll(gestureListeners ?? {});
    _nodeListeners.addAll(nodeListeners ?? {});
    _arrowDelegates.addAll(arrowDelegates ?? {});
    _menuListeners.addAll(optionalMenuListeners ?? {});
  }

  ListenerCollection copy({
    Set<ValueChanged<BasicCursor>>? cursorListeners,
    Set<ValueChanged<List<EditorNode>>>? nodesListeners,
    Map<String, Set<GestureStateListener>>? gestureListeners,
    Map<String, Set<ValueChanged<EditorNode>>>? nodeListeners,
    Map<String, Set<ArrowDelegate>>? arrowDelegates,
    Set<ValueChanged<OptionalSelectedType>>? optionalMenuListeners,
  }) =>
      ListenerCollection(
        cursorListeners: cursorListeners ?? _cursorListeners,
        nodesListeners: nodesListeners ?? _nodesListeners,
        gestureListeners: gestureListeners ?? _gestureListeners,
        nodeListeners: nodeListeners ?? _nodeListeners,
        arrowDelegates: arrowDelegates ?? _arrowDelegates,
        optionalMenuListeners: optionalMenuListeners ?? _menuListeners,
      );

  void dispose() {
    logger.i('$tag, dispose');
    _cursorListeners.clear();
    _nodesListeners.clear();
    _gestureListeners.clear();
    _nodeListeners.clear();
    _arrowDelegates.clear();
    _menuListeners.clear();
  }

  void addCursorChangedListener(ValueChanged<BasicCursor> listener) =>
      _cursorListeners.add(listener);

  void removeCursorChangedListener(ValueChanged<BasicCursor> listener) =>
      _cursorListeners.remove(listener);

  void addNodesChangedListener(ValueChanged<List<EditorNode>> listener) =>
      _nodesListeners.add(listener);

  void removeNodesChangedListener(ValueChanged<List<EditorNode>> listener) =>
      _nodesListeners.remove(listener);

  void addGestureListener(String id, GestureStateListener listener) {
    final set = _gestureListeners[id] ?? {};
    set.add(listener);
    _gestureListeners[id] = set;
  }

  void removeGestureListener(String id, GestureStateListener listener) {
    final set = _gestureListeners[id] ?? {};
    set.remove(listener);
    _gestureListeners[id] = set;
  }

  void addOptionalMenuListener(ValueChanged<OptionalSelectedType> listener) =>
      _menuListeners.add(listener);

  void removeOptionalMenuListener(
          ValueChanged<OptionalSelectedType> listener) =>
      _menuListeners.remove(listener);

  void addNodeChangedListener(String id, ValueChanged<EditorNode> listener) {
    // logger.i(
    //     '$tag, addNodeChangedCallback:$id, all:${_nodeChangedCallbacks.length}');
    final set = _nodeListeners[id] ?? {};
    set.add(listener);
    _nodeListeners[id] = set;
  }

  void removeNodeChangedListener(String id, ValueChanged<EditorNode> listener) {
    final set = _nodeListeners[id] ?? {};
    set.remove(listener);
    // logger.i('$tag, removeNodeChangedCallback:$id, length:${set.length}');
    if (set.isEmpty) {
      _nodeListeners.remove(id);
    } else {
      _nodeListeners[id] = set;
    }
  }

  void addArrowDelegate(String id, ArrowDelegate callback) {
    // logger.i('$tag, addArrowDelegate:$id, all:${_arrowDelegates.length}');
    final set = _arrowDelegates[id] ?? {};
    set.add(callback);
    _arrowDelegates[id] = set;
  }

  void removeArrowDelegate(String id, ArrowDelegate callback) {
    final set = _arrowDelegates[id] ?? {};
    set.remove(callback);
    // logger.i(
    //     '$tag, addArrowDelegate:$id, length:${set.length}, all:${_arrowDelegates.length}');
    if (set.isEmpty) {
      _arrowDelegates.remove(id);
    } else {
      _arrowDelegates[id] = set;
    }
  }

  void onArrowAccept(AcceptArrowData data) {
    final id = data.id;
    final set = _arrowDelegates[id] ?? {};
    if (set.isEmpty) throw NodeNotFoundException(id);
    // logger.i(
    //     '$tag, onArrowAccept, id:$id, type:${data.type}, length:${set.length}, all:${_arrowDelegates.length}');
    for (var c in Set.of(set)) {
      c.call(data);
    }
  }

  void notifyCursor(BasicCursor cursor) {
    for (var c in Set.of(_cursorListeners)) {
      c.call(cursor);
    }
    // logger.i('$tag, notifyCursor length:${_cursorChangedCallbacks.length}');
  }

  ///return the accepted node id
  String? notifyGestures(GestureState state) {
    for (var k in _gestureListeners.keys) {
      final v = _gestureListeners[k];
      for (var c in Set.of(v ?? {})) {
        final accepted = c.call(state);
        if(accepted) return k;
      }
    }
    return null;
    // logger.i(
    //     '$tag, notifyDragUpdateDetails length:${_onPanUpdateCallbacks.length}');
  }

  bool notifyGesture(String id, GestureState state) {
    final set = Set.of(_gestureListeners[id] ?? {});
    for (var c in set) {
      final v = c.call(state);
      if(v) return v;
    }
    return false;
  }

  void notifyNode(EditorNode node) {
    for (var c in Set.of(_nodeListeners[node.id] ?? {})) {
      c.call(node);
    }
    // logger
    //     .i('$tag, notifyNode length:${_nodeChangedCallbacks[node.id]?.length}');
  }

  void notifyNodes(List<EditorNode> nodes) {
    for (var c in Set.of(_nodesListeners)) {
      c.call(nodes);
    }
    // logger.i('$tag, notifyNodes length:${_nodesChangedCallbacks.length}');
  }

  void notifyOptionalMenu(OptionalSelectedType type) {
    for (var c in Set.of(_menuListeners)) {
      c.call(type);
    }
  }

  ListenerCollection? getListener(String id) {
    final set = _id2Listeners[id];
    if (set == null || set.isEmpty) return null;
    return set.first;
  }

  void addListener(String id, ListenerCollection l) {
    final set = _id2Listeners[id] ?? {};
    set.add(l);
    _id2Listeners[id] = set;
  }

  void removeListener(String id, ListenerCollection l) {
    final set = _id2Listeners[id] ?? {};
    set.remove(l);
    if (set.isEmpty) {
      _id2Listeners.remove(id);
    } else {
      _id2Listeners[id] = set;
    }
  }
}

typedef GestureStateListener = bool Function(GestureState s);

abstract class GestureState {
  Offset get globalOffset;
}

class TapGestureState implements GestureState {
  @override
  final Offset globalOffset;

  TapGestureState(this.globalOffset);
}

class HoverGestureState implements GestureState {
  @override
  final Offset globalOffset;

  HoverGestureState(this.globalOffset);
}

class PanGestureState implements GestureState {
  @override
  final Offset globalOffset;
  final Offset beginOffset;

  PanGestureState(this.globalOffset, this.beginOffset);
}

class CursorOffset {
  final int index;
  final EditingOffset offset;

  CursorOffset(this.index, this.offset);

  CursorOffset.zero()
      : index = 0,
        offset = EditingOffset.zero();

  double get y => offset.y;

  @override
  String toString() {
    return 'CursorOffset{index: $index, offset: $offset}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CursorOffset &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          offset == other.offset;

  @override
  int get hashCode => index.hashCode ^ offset.hashCode;
}
