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
  final Set<VoidCallback> _nodesListeners = {};
  final Map<String, Set<ValueChanged<GestureState>>> _gestureListeners = {};
  final Set<ValueChanged<ControllerStatus>> _statusListeners = {};
  final Map<String, Set<ValueChanged<EditorNode>>> _nodeListeners = {};
  final Map<String, Set<ArrowDelegate>> _arrowDelegates = {};
  final Set<ValueChanged<OptionalSelectedType>> _optionalMenuListeners = {};
  final Map<String, Set<ListenerCollection>> _id2Listeners = {};

  ListenerCollection({
    Set<ValueChanged<BasicCursor>>? cursorListeners,
    Set<VoidCallback>? nodesListeners,
    Map<String, Set<ValueChanged<GestureState>>>? gestureListeners,
    Set<ValueChanged<ControllerStatus>>? statusListeners,
    Map<String, Set<ValueChanged<EditorNode>>>? nodeListeners,
    Map<String, Set<ArrowDelegate>>? arrowDelegates,
    Set<ValueChanged<OptionalSelectedType>>? optionalMenuListeners,
  }) {
    _cursorListeners.addAll(cursorListeners ?? {});
    _nodesListeners.addAll(nodesListeners ?? {});
    _gestureListeners.addAll(gestureListeners ?? {});
    _statusListeners.addAll(statusListeners ?? {});
    _nodeListeners.addAll(nodeListeners ?? {});
    _arrowDelegates.addAll(arrowDelegates ?? {});
    _optionalMenuListeners.addAll(optionalMenuListeners ?? {});
  }

  ListenerCollection copy({
    Set<ValueChanged<BasicCursor>>? cursorListeners,
    Set<VoidCallback>? nodesListeners,
    Map<String, Set<ValueChanged<GestureState>>>? gestureListeners,
    Set<ValueChanged<ControllerStatus>>? statusListeners,
    Map<String, Set<ValueChanged<EditorNode>>>? nodeListeners,
    Map<String, Set<ArrowDelegate>>? arrowDelegates,
    Set<ValueChanged<OptionalSelectedType>>? optionalMenuListeners,
  }) =>
      ListenerCollection(
        cursorListeners: cursorListeners ?? _cursorListeners,
        nodesListeners: nodesListeners ?? _nodesListeners,
        gestureListeners: gestureListeners ?? _gestureListeners,
        statusListeners: statusListeners ?? _statusListeners,
        nodeListeners: nodeListeners ?? _nodeListeners,
        arrowDelegates: arrowDelegates ?? _arrowDelegates,
        optionalMenuListeners: optionalMenuListeners ?? _optionalMenuListeners,
      );

  void dispose() {
    logger.i('$tag, dispose');
    _cursorListeners.clear();
    _nodesListeners.clear();
    _gestureListeners.clear();
    _statusListeners.clear();
    _nodeListeners.clear();
    _arrowDelegates.clear();
    _optionalMenuListeners.clear();
  }

  void addCursorChangedListener(ValueChanged<BasicCursor> listener) =>
      _cursorListeners.add(listener);

  void removeCursorChangedListener(ValueChanged<BasicCursor> listener) =>
      _cursorListeners.remove(listener);

  void addNodesChangedListener(VoidCallback listener) =>
      _nodesListeners.add(listener);

  void removeNodesChangedListener(VoidCallback listener) =>
      _nodesListeners.remove(listener);

  void addGestureListener(String id, ValueChanged<GestureState> listener) {
    final set = _gestureListeners[id] ?? {};
    set.add(listener);
    _gestureListeners[id] = set;
  }

  void removeGestureListener(String id, ValueChanged<GestureState> listener) {
    final set = _gestureListeners[id] ?? {};
    set.remove(listener);
    _gestureListeners[id] = set;
  }

  void addStatusChangedListener(ValueChanged<ControllerStatus> listener) =>
      _statusListeners.add(listener);

  void removeStatusChangedListener(ValueChanged<ControllerStatus> listener) =>
      _statusListeners.remove(listener);

  void addOptionalMenuListener(ValueChanged<OptionalSelectedType> listener) =>
      _optionalMenuListeners.add(listener);

  void removeOptionalMenuListener(
          ValueChanged<OptionalSelectedType> listener) =>
      _optionalMenuListeners.remove(listener);

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

  void notifyGestures(GestureState state) {
    for (var o in _gestureListeners.values) {
      for (var c in Set.of(o)) {
        c.call(state);
      }
    }
    // logger.i(
    //     '$tag, notifyDragUpdateDetails length:${_onPanUpdateCallbacks.length}');
  }

  void notifyGesture(String id, GestureState state) {
    final set = Set.of(_gestureListeners[id] ?? {});
    for (var c in set) {
      c.call(state);
    }
  }

  void notifyNode(EditorNode node) {
    for (var c in Set.of(_nodeListeners[node.id] ?? {})) {
      c.call(node);
    }
    // logger
    //     .i('$tag, notifyNode length:${_nodeChangedCallbacks[node.id]?.length}');
  }

  void notifyNodes() {
    for (var c in Set.of(_nodesListeners)) {
      c.call();
    }
    // logger.i('$tag, notifyNodes length:${_nodesChangedCallbacks.length}');
  }

  void notifyStatus(ControllerStatus status) {
    for (var c in Set.of(_statusListeners)) {
      c.call(status);
    }
  }

  void notifyOptionalMenu(OptionalSelectedType type) {
    for (var c in Set.of(_optionalMenuListeners)) {
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
