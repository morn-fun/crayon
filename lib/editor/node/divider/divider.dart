import 'package:flutter/material.dart';
import '../../../editor/core/context.dart';
import '../../../editor/cursor/rich_text.dart';
import '../../cursor/basic.dart';
import '../../cursor/divider.dart';
import '../../exception/editor_node.dart';
import '../../widget/nodes/divider.dart';
import '../basic.dart';
import '../rich_text/rich_text.dart';

class DividerNode extends EditorNode {
  DividerNode.from({super.depth, super.id});

  @override
  DividerPosition get beginPosition => dividerPosition;

  @override
  Widget build(NodesOperator operator, NodeBuildParam param, BuildContext c) =>
      DividerWidget(operator: operator, param: param, node: this);

  @override
  DividerPosition get endPosition => dividerPosition;

  @override
  EditorNode getFromPosition(
          covariant DividerPosition begin, covariant DividerPosition end,
          {String? newId}) =>
      DividerNode.from(id: newId ?? id);

  @override
  List<EditorNode> getInlineNodesFromPosition(
          covariant DividerPosition begin, covariant DividerPosition end) =>
      [];

  @override
  EditorNode merge(EditorNode other, {String? newId}) {
    throw UnableToMergeException('$runtimeType', '${other.runtimeType}');
  }

  @override
  EditorNode newNode({String? id, int? depth}) =>
      DividerNode.from(depth: depth ?? this.depth, id: id ?? this.id);

  @override
  NodeWithCursor onEdit(EditingData data) {
    final generator = _editingGenerator[data.type.name];
    if (generator == null) {
      throw NodeUnsupportedException(
          runtimeType, 'onEdit without generator', data);
    }
    return generator.call(data.as<DividerPosition>(), this);
  }

  @override
  NodeWithCursor onSelect(SelectingData data) {
    final type = data.type;
    final generator = _selectingGenerator[type.name];
    if (generator == null) {
      throw NodeUnsupportedException(
          runtimeType, 'onSelect without generator', data);
    }
    return generator.call(data.as<DividerPosition>(), this);
  }

  @override
  String get text => '---';

  @override
  @override
  Map<String, dynamic> toJson() => {'type': '$runtimeType'};

  NodeWithCursor onDelete(int index) => NodeWithCursor(
      RichTextNode.from([]), EditingCursor(index, RichTextNodePosition.zero()));

  NodeWithCursor onNewline() => throw NewlineRequiresNewSpecialNode(
      [RichTextNode.from([]), RichTextNode.from([])],
      RichTextNodePosition.zero());

  NodeWithCursor onPaste(dynamic extra) {
    List<EditorNode> newNodes = extra is List<EditorNode> ? extra : [];
    if (newNodes.isEmpty) newNodes = [RichTextNode.from([])];
    if (newNodes.isEmpty) {
      throw NodeUnsupportedException(
          runtimeType, 'onPaste without extra', extra);
    }
    throw PasteToCreateMoreNodesException(
        newNodes, runtimeType, newNodes.last.endPosition);
  }

  NodeWithCursor onIncreaseDepth(dynamic extras, SingleNodeCursor cursor) {
    int lastDepth = extras is int ? extras : 0;
    int depth = this.depth;
    if (lastDepth < depth) {
      throw NodeUnsupportedException(runtimeType,
          'increaseDepth with depth $lastDepth small than $depth', depth);
    }
    return NodeWithCursor(newNode(depth: depth + 1), cursor);
  }
}

final _editingGenerator = <String, _NodeGeneratorWhileEditing>{
  EventType.delete.name: (d, n) => n.onDelete(d.index),
  EventType.newline.name: (d, n) => n.onNewline(),
  EventType.selectAll.name: (d, n) => throw EmptyNodeToSelectAllException(n.id),
  EventType.paste.name: (d, n) => n.onPaste(d.extras),
  EventType.increaseDepth.name: (d, n) => n.onIncreaseDepth(d.extras, d.cursor),
  EventType.decreaseDepth.name: (d, n) =>
      throw DepthNeedDecreaseMoreException(n.runtimeType, n.depth),
};

final _selectingGenerator = <String, _NodeGeneratorWhileSelecting>{
  EventType.delete.name: (d, n) => n.onDelete(d.index),
  EventType.newline.name: (d, n) => n.onNewline(),
  EventType.paste.name: (d, n) => n.onPaste(d.extras),
  EventType.increaseDepth.name: (d, n) => n.onIncreaseDepth(d.extras, d.cursor),
  EventType.decreaseDepth.name: (d, n) =>
      throw DepthNeedDecreaseMoreException(n.runtimeType, n.depth),
};

typedef _NodeGeneratorWhileSelecting = NodeWithCursor Function(
    SelectingData<DividerPosition> data, DividerNode node);

typedef _NodeGeneratorWhileEditing = NodeWithCursor Function(
    EditingData<DividerPosition> data, DividerNode node);
