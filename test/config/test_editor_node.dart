import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/node/basic.dart';

class TestEditorNode extends EditorNode {
  @override
  // TODO: implement beginPosition
  NodePosition get beginPosition => TestNodePosition();

  @override
  Widget build(NodesOperator context, NodeBuildParam param, BuildContext c) {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  NodePosition get endPosition => TestNodePosition();

  @override
  EditorNode frontPartNode(NodePosition end, {String? newId}) {
    // TODO: implement frontPartNode
    throw UnimplementedError();
  }

  @override
  EditorNode getFromPosition(NodePosition begin, NodePosition end,
      {String? newId}) {
    // TODO: implement getFromPosition
    throw UnimplementedError();
  }

  @override
  EditorNode merge(EditorNode other, {String? newId}) {
    if (other is TestEditorNode) return this;
    throw UnableToMergeException('$runtimeType', '${other.runtimeType}');
  }

  @override
  EditorNode newNode({String? id, int? depth}) {
    // TODO: implement newIdNode
    throw UnimplementedError();
  }

  @override
  NodeWithCursor<NodePosition> onEdit(EditingData<NodePosition> data) {
    // TODO: implement onEdit
    throw UnimplementedError();
  }

  @override
  NodeWithCursor<NodePosition> onSelect(SelectingData<NodePosition> data) {
    // TODO: implement onSelect
    throw UnimplementedError();
  }

  @override
  EditorNode rearPartNode(NodePosition begin, {String? newId}) {
    // TODO: implement rearPartNode
    throw UnimplementedError();
  }

  @override
  // TODO: implement text
  String get text => throw UnimplementedError();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  List<EditorNode> getInlineNodesFromPosition(
      NodePosition begin, NodePosition end) {
    // TODO: implement getInlineNodesFromPosition
    throw UnimplementedError();
  }
}

class TestNodePosition extends NodePosition {
  @override
  bool isLowerThan(NodePosition other) => false;
}
