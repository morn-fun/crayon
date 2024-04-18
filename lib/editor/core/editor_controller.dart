import 'dart:collection';

import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import '../shortcuts/arrows/arrows.dart';
import 'listener_collection.dart';
import 'command_invoker.dart';

class RichEditorController {
  RichEditorController.fromNodes(List<EditorNode> nodes) {
    for (var n in nodes) {
      _id2Index[n.id] = _nodes.length;
      _nodes.add(n);
    }
    _checkLength();
  }

  final List<EditorNode> _nodes = [];
  final Map<String, int> _id2Index = {};
  ControllerStatus _status = ControllerStatus.idle;
  BasicCursor _cursor = NoneCursor();

  final ListenerCollection listeners = ListenerCollection();

  EditorNode getNode(int index) => _nodes[index];

  int? getIndex(String id) => _id2Index[id];

  Iterable<EditorNode> getRange(int begin, int end) =>
      _nodes.getRange(begin, end);

  EditorNode get firstNode => _nodes.first;

  EditorNode get lastNode => _nodes.last;

  void _checkLength() {
    assert(_id2Index.length == _nodes.length);
  }

  SelectingNodesCursor get selectAllCursor => SelectingNodesCursor(
      IndexWithPosition(0, firstNode.beginPosition),
      IndexWithPosition(nodeLength - 1, lastNode.endPosition));

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
    _cursor = cursor;
    if (notify) notifyCursor(cursor);
  }

  void updateStatus(ControllerStatus status) {
    if (_status == status) return;
    _status = status;
    _notifyStatus(status);
  }

  void onArrowAccept(AcceptArrowData data) => listeners.onArrowAccept(data);

  void notifyCursor(BasicCursor cursor) => listeners.notifyCursor(cursor);

  void _notifyStatus(ControllerStatus status) => listeners.notifyStatus(status);

  void notifyGesture(GestureState s) => listeners.notifyGesture(s);

  void notifyNode(EditorNode node) => listeners.notifyNode(node);

  void notifyNodes() => listeners.notifyNodes();

  void notifyEditingCursorOffset(CursorOffset indexY) =>
      listeners.notifyEditingCursorOffset(indexY);

  List<Map<String, dynamic>> toJson() => _nodes.map((e) => e.toJson()).toList();

  void dispose() {
    _nodes.clear();
    _id2Index.clear();
    listeners.dispose();
  }

  UnmodifiableListView<EditorNode> get nodes => UnmodifiableListView(_nodes);

  BasicCursor get cursor => _cursor;

  int get nodeLength => _nodes.length;

  ControllerStatus get status => _status;
}

class Update extends UpdateControllerOperation {
  final int index;
  final EditorNode node;
  final BasicCursor cursor;

  Update(this.index, this.node, this.cursor);

  @override
  UpdateControllerOperation update(RichEditorController controller) {
    final nodes = controller._nodes;
    final id2Index = controller._id2Index;
    final undoOperation = Update(index, nodes[index], controller.cursor);
    final oldNode = nodes[index];
    id2Index.remove(oldNode.id);
    nodes[index] = node;
    id2Index[node.id] = index;
    controller._checkLength();
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
    final id2Index = controller._id2Index;
    final oldNodes = nodes.sublist(begin, end);
    for (var n in oldNodes) {
      id2Index.remove(n.id);
    }
    final operation =
        Replace(begin, begin + newNodes.length, oldNodes, controller.cursor);
    nodes.replaceRange(begin, end, List.of(newNodes));
    for (var i = begin; i < nodes.length; ++i) {
      var n = nodes[i];
      id2Index[n.id] = i;
    }
    controller._checkLength();
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
