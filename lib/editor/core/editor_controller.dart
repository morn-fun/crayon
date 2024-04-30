import 'dart:collection';

import '../cursor/basic.dart';
import '../node/basic.dart';
import '../shortcuts/arrows/arrows.dart';
import 'listener_collection.dart';
import 'command_invoker.dart';

class RichEditorController {
  RichEditorController.fromNodes(List<EditorNode> nodes) {
    _nodes.addAll(nodes);
  }

  final List<EditorNode> _nodes = [];
  ControllerStatus _status = ControllerStatus.idle;
  BasicCursor _cursor = NoneCursor();

  final ListenerCollection listeners = ListenerCollection();

  EditorNode getNode(int index) => _nodes[index];

  Iterable<EditorNode> getRange(int begin, int end) =>
      _nodes.getRange(begin, end);

  EditorNode get firstNode => _nodes.first;

  EditorNode get lastNode => _nodes.last;

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
