import 'dart:collection';

import '../../../../editor/extension/unmodifiable.dart';
import '../../../../editor/node/rich_text/rich_text.dart';
import '../../core/copier.dart';
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

  TableCell moveTo(int from, int to) {
    final newNodes = nodes.toList();
    final fromNode = newNodes.removeAt(from);
    newNodes.insert(from < to ? to - 1 : to, fromNode);
    return copy(nodes: newNodes);
  }

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

  TableCell newIdCell() {
    List<EditorNode> nodes = [];
    for (var node in this.nodes) {
      nodes.add(node.newNode(id: randomNodeId));
    }
    return TableCell(nodes);
  }
}
