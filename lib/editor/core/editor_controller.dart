import 'dart:collection';

import 'package:flutter/material.dart';

import '../cursor/basic.dart';
import '../cursor/rich_text.dart';
import '../node/basic.dart';
import '../shortcuts/arrows/arrows.dart';
import 'listener_collection.dart';
import 'command_invoker.dart';
import 'logger.dart';

class RichEditorController {
  RichEditorController.fromNodes(List<EditorNode> nodes) {
    _nodes.addAll(nodes);
  }

  final List<EditorNode> _nodes = [];
  ControllerStatus _status = ControllerStatus.idle;
  BasicCursor _cursor = NoneCursor();
  CursorOffset _lastCursorOffset = CursorOffset.zero();
  EditingCursor _panBeginCursor = EditingCursor(0, RichTextNodePosition.zero());
  EditingCursor? _panEndCursor;
  final Set<ValueChanged<ControllerStatus>> _statusListeners = {};
  final Set<ValueChanged<CursorOffset>> _cursorOffsetListeners = {};

  final tag = 'RichEditorController';

  final ListenerCollection listeners = ListenerCollection();

  EditorNode getNode(int index) => _nodes[index];

  Iterable<EditorNode> getRange(int begin, int end) =>
      _nodes.getRange(begin, end);

  EditorNode get firstNode => _nodes.first;

  EditorNode get lastNode => _nodes.last;

  BasicCursor get selectAllCursor =>
      nodeLength == 1
          ? SelectingNodeCursor(
          0, nodes.first.beginPosition, nodes.last.endPosition)
          : SelectingNodesCursor(EditingCursor(0, firstNode.beginPosition),
          EditingCursor(nodeLength - 1, lastNode.endPosition));

  UpdateControllerOperation? update(Update data, {bool record = true}) {
    final operation = data.update(this);
    return record ? operation : null;
  }

  UpdateControllerOperation? replace(Replace data, {bool record = true}) {
    final operation = data.update(this);
    return record ? operation : null;
  }

  void updateCursor(BasicCursor cursor, {bool notify = true}) {
    if (_cursor == cursor) return;
    logger.i('$tag, updateCursor: $cursor');
    _cursor = cursor;
    if (cursor is EditingCursor) _updatePanStartCursor(cursor);
    if (notify) notifyCursor(cursor);
  }

  void updateStatus(ControllerStatus status) {
    if (_status == status) return;
    logger.i('$tag, updateStatus: $status');
    _status = status;
    for (var c in Set.of(_statusListeners)) {
      c.call(status);
    }
  }

  void updatePanEndCursor(EditingCursor cursor) {
    if (_panEndCursor == cursor) return;
    logger.i('$tag, updatePanEndCursor: $cursor');
    _panEndCursor = cursor;
  }

  void addStatusChangedListener(ValueChanged<ControllerStatus> listener) =>
      _statusListeners.add(listener);

  void removeStatusChangedListener(ValueChanged<ControllerStatus> listener) =>
      _statusListeners.remove(listener);

  void addCursorOffsetListeners(ValueChanged<CursorOffset> listener) =>
      _cursorOffsetListeners.add(listener);

  void removeCursorOffsetListeners(ValueChanged<CursorOffset> listener) =>
      _cursorOffsetListeners.remove(listener);

  void _updatePanStartCursor(EditingCursor c) {
    _panBeginCursor = c;
    _panEndCursor = null;
  }

  void onArrowAccept(AcceptArrowData data) => listeners.onArrowAccept(data);

  void notifyCursor(BasicCursor cursor) => listeners.notifyCursor(cursor);

  String? notifyGesture(GestureState s) => listeners.notifyGestures(s);

  void notifyNode(EditorNode node) => listeners.notifyNode(node);

  void notifyNodes() => listeners.notifyNodes(nodes);

  void setCursorOffset(CursorOffset o) {
    _lastCursorOffset = o;
    for (var c in Set.of(_cursorOffsetListeners)) {
      c.call(o);
    }
  }

  List<Map<String, dynamic>> toJson() => _nodes.map((e) => e.toJson()).toList();

  void dispose() {
    _nodes.clear();
    _statusListeners.clear();
    _cursorOffsetListeners.clear();
    listeners.dispose();
  }

  UnmodifiableListView<EditorNode> get nodes => UnmodifiableListView(_nodes);

  BasicCursor get cursor => _cursor;

  int get nodeLength => _nodes.length;

  ControllerStatus get status => _status;

  CursorOffset get lastCursorOffset => _lastCursorOffset;

  EditingCursor get panBeginCursor => _panBeginCursor;

  EditingCursor? get panEndCursor => _panEndCursor;
}

class Update extends UpdateControllerOperation {
  final int index;
  final EditorNode node;
  final BasicCursor cursor;

  Update(this.index, this.node, this.cursor);

  @override
  UpdateControllerOperation update(RichEditorController controller) {
    final nodes = controller._nodes;
    final undoOperation = Update(index, nodes[index], controller.cursor);
    nodes[index] = node;
    controller.updateCursor(cursor, notify: false);
    controller.notifyNode(node);
    controller.notifyCursor(cursor);
    return undoOperation;
  }
}

class Replace extends UpdateControllerOperation {
  final int begin;
  final int end;
  final UnmodifiableListView<EditorNode> newNodes;
  final BasicCursor cursor;

  Replace(this.begin, this.end, List<EditorNode> nodes, this.cursor)
      : newNodes = UnmodifiableListView(nodes);

  @override
  UpdateControllerOperation update(RichEditorController controller) {
    final nodes = controller._nodes;
    final oldNodes = nodes.sublist(begin, end);
    final operation =
    Replace(begin, begin + newNodes.length, oldNodes, controller.cursor);
    nodes.replaceRange(begin, end, List.of(newNodes));
    controller.updateCursor(cursor, notify: false);
    controller.notifyNodes();
    controller.notifyCursor(cursor);
    return operation;
  }

  @override
  bool get enableThrottle => false;
}

enum ControllerStatus {
  typing,
  idle,
}

class EditingOffset {
  final Offset offset;
  final double height;
  final String nodeId;

  EditingOffset(this.offset, this.height, this.nodeId);

  EditingOffset.zero()
      : offset = Offset.zero,
        height = 0.0,
        nodeId = '';

  double get y => offset.dy;

  @override
  String toString() {
    return 'EditingOffset{offset: $offset, height: $height, nodeId: $nodeId}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is EditingOffset &&
              runtimeType == other.runtimeType &&
              offset == other.offset &&
              height == other.height &&
              nodeId == other.nodeId;

  @override
  int get hashCode => offset.hashCode ^ height.hashCode ^ nodeId.hashCode;
}
