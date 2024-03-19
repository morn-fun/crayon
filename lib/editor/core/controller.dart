import 'dart:collection';

import 'package:flutter/material.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import '../shortcuts/arrows.dart';
import 'callbacks_collection.dart';
import 'command_invoker.dart';
import 'logger.dart';

class RichEditorController {
  RichEditorController.fromNodes(List<EditorNode> nodes) {
    _nodes.addAll(List.of(nodes));
  }

  final _tag = 'RichEditorController';

  final List<EditorNode> _nodes = [];
  BasicCursor _cursor = NoneCursor();

  final CallbackCollection _callbackCollection = CallbackCollection();

  void addCursorChangedCallback(ValueChanged<BasicCursor> callback) =>
      _callbackCollection.addCursorChangedCallback(callback);

  void removeCursorChangedCallback(ValueChanged<BasicCursor> callback) =>
      _callbackCollection.removeCursorChangedCallback(callback);

  void addNodesChangedCallback(VoidCallback callback) =>
      _callbackCollection.addNodesChangedCallback(callback);

  void addPanUpdateCallback(ValueChanged<Offset> callback) =>
      _callbackCollection.addPanUpdateCallback(callback);

  void removePanUpdateCallback(ValueChanged<Offset> callback) =>
      _callbackCollection.removePanUpdateCallback(callback);

  void addNodeChangedCallback(String id, ValueChanged<EditorNode> callback) =>
      _callbackCollection.addNodeChangedCallback(id, callback);

  void removeNodeChangedCallback(
          String id, ValueChanged<EditorNode> callback) =>
      _callbackCollection.removeNodeChangedCallback(id, callback);

  void addArrowDelegate(String id, ArrowDelegate callback) =>
      _callbackCollection.addArrowDelegate(id, callback);

  void removeArrowDelegate(String id, ArrowDelegate callback) =>
      _callbackCollection.removeArrowDelegate(id, callback);

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

  void onArrowAccept(int index, ArrowType type, NodePosition position) =>
      _callbackCollection.onArrowAccept(_nodes[index].id, type, position);

  void notifyCursor(BasicCursor cursor) =>
      _callbackCollection.notifyCursor(cursor);

  void notifyDragUpdateDetails(Offset p) =>
      _callbackCollection.notifyDragUpdateDetails(p);

  void notifyNode(EditorNode node) => _callbackCollection.notifyNode(node);

  void notifyNodes() => _callbackCollection.notifyNodes();

  List<Map<String, dynamic>> toJson() => _nodes.map((e) => e.toJson()).toList();

  void dispose() {
    _nodes.clear();
    _callbackCollection.dispose();
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
