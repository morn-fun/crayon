import 'dart:collection';
import 'package:flutter/material.dart';

import '../../../../editor/extension/unmodifiable.dart';
import '../../../../editor/node/rich_text/rich_text.dart';
import '../../../../editor/command/basic.dart';
import '../../../../editor/core/command_invoker.dart';
import '../../../../editor/core/editor_controller.dart';
import '../../../../editor/core/listener_collection.dart';
import '../../core/context.dart';
import '../../core/copier.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../basic.dart';

class TableCell {
  final UnmodifiableListView<EditorNode> nodes;
  final String id;

  TableCell(List<EditorNode> nodes, {String? id})
      : nodes = _initNodes(nodes),
        id = id ?? randomNodeId;

  TableCell.empty({String? id})
      : nodes = _initNodes([]),
        id = id ?? randomNodeId;

  TableCell copy({List<EditorNode>? nodes, String? id}) =>
      TableCell(nodes ?? this.nodes, id: id ?? this.id);

  static UnmodifiableListView<EditorNode> _initNodes(List<EditorNode> nodes) {
    if (nodes.isEmpty) return UnmodifiableListView([RichTextNode.from([])]);
    return UnmodifiableListView(nodes);
  }

  int get length => nodes.length;

  EditorNode get last => nodes.last;

  EditorNode get first => nodes.first;

  EditingCursor get beginCursor => EditingCursor(0, first.beginPosition);

  EditingCursor get endCursor => EditingCursor(length - 1, last.endPosition);

  BasicCursor get selectAllCursor => length == 1
      ? SelectingNodeCursor(0, first.beginPosition, last.endPosition)
      : SelectingNodesCursor(beginCursor, endCursor);

  EditorNode getNode(int index) => nodes[index];

  TableCell clear() => copy(nodes: []);

  bool isBegin(EditingCursor p) {
    if (p.index != 0) return false;
    if (p.position != first.beginPosition) return false;
    return true;
  }

  bool isEnd(EditingCursor p) {
    if (p.index != length - 1) return false;
    if (p.position != last.endPosition) return false;
    return true;
  }

  bool wholeSelected(BasicCursor? cursor) => cursor == selectAllCursor;

  TableCell update(int index, ValueCopier<EditorNode> copier) =>
      copy(nodes: nodes.update(index, copier));

  TableCell replaceMore(int begin, int end, Iterable<EditorNode> newNodes) =>
      copy(nodes: nodes.replaceMore(begin, end, newNodes));

  List<EditorNode> getNodes(EditingCursor begin, EditingCursor end) {
    final left = begin.isLowerThan(end) ? begin : end;
    final right = begin.isLowerThan(end) ? end : begin;
    final leftNode = getNode(left.index);
    final rightNode = getNode(right.index);
    if (left.index == right.index) {
      return [
        leftNode.getFromPosition(left.position, right.position,
            newId: randomNodeId)
      ];
    } else {
      final newLeftNode =
          leftNode.rearPartNode(left.position, newId: randomNodeId);
      final newRightNode =
          rightNode.frontPartNode(right.position, newId: randomNodeId);
      return [
        newLeftNode,
        if (left.index < right.index + 1)
          ...nodes.getRange(left.index + 1, right.index),
        newRightNode
      ];
    }
  }

  Map<String, dynamic> toJson() =>
      {'type': '$runtimeType', 'nodes': nodes.map((e) => e.toJson()).toList()};

  String get text => nodes.map((e) => e.text).join('\n');
}

class TableCellNodeContext extends NodeContext {
  final ValueGetter<BasicCursor> cursorGetter;
  final ValueGetter<TableCell> cellGetter;
  final ValueChanged<Replace> onReplace;
  final ValueChanged<Update> onUpdate;
  final ValueChanged<BasicCursor> onBasicCursor;
  final ValueChanged<EditingOffset> editingOffset;
  final ValueChanged<EditingCursor> onPan;
  final ValueChanged<NodeWithIndex> onNodeUpdate;
  @override
  final ListenerCollection listeners;

  TableCellNodeContext({
    required this.cursorGetter,
    required this.cellGetter,
    required this.listeners,
    required this.onReplace,
    required this.onUpdate,
    required this.onBasicCursor,
    required this.editingOffset,
    required this.onPan,
    required this.onNodeUpdate,
  });

  final tag = 'TableCellNodeContext';

  TableCell get cell => cellGetter.call();

  @override
  void execute(BasicCommand command) {
    try {
      command.run(this);
    } catch (e) {
      logger.e('execute 【$command】error:$e');
    }
  }

  @override
  EditorNode getNode(int index) => cell.getNode(index);

  @override
  Iterable<EditorNode> getRange(int begin, int end) =>
      cell.nodes.getRange(begin, end);

  @override
  List<EditorNode> get nodes => cell.nodes;

  @override
  UpdateControllerOperation? replace(Replace data, {bool record = true}) {
    onReplace.call(data);
    return null;
  }

  @override
  SelectingNodesCursor<NodePosition> get selectAllCursor =>
      SelectingNodesCursor(EditingCursor(0, cell.first.beginPosition),
          EditingCursor(cell.length - 1, cell.last.endPosition));

  @override
  UpdateControllerOperation? update(Update data, {bool record = true}) {
    onUpdate.call(data);
    return null;
  }

  @override
  BasicCursor get cursor => cursorGetter.call();

  @override
  void onCursor(BasicCursor cursor) => onBasicCursor.call(cursor);

  @override
  void onEditingOffset(EditingOffset o) => editingOffset.call(o);

  @override
  void onPanUpdate(EditingCursor cursor) => onPan(cursor);

  @override
  void onNode(EditorNode node, int index) =>
      onNodeUpdate.call(NodeWithIndex(node, index));
}

class NodeWithIndex {
  final EditorNode node;
  final int index;

  NodeWithIndex(this.node, this.index);
}
