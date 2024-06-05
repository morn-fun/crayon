import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import '../core/context.dart';
import '../cursor/basic.dart';
import '../exception/editor_node.dart';

@immutable
abstract class EditorNode {
  EditorNode({String? id, this.depth = 0}) : _id = id ?? randomNodeId;

  final String _id;

  final int depth;

  Map<String, dynamic> toJson();

  Widget build(NodesOperator operator, NodeBuildParam param, BuildContext c);

  EditorNode frontPartNode(NodePosition end, {String? newId}) =>
      getFromPosition(beginPosition, end, newId: newId);

  EditorNode rearPartNode(NodePosition begin, {String? newId}) =>
      getFromPosition(begin, endPosition, newId: newId);

  EditorNode getFromPosition(NodePosition begin, NodePosition end,
      {String? newId});

  NodeWithCursor onEdit(EditingData data);

  NodeWithCursor onSelect(SelectingData data);

  /// if cannot merge, this function will throw an exception [UnableToMergeException]
  EditorNode merge(EditorNode other, {String? newId});

  List<EditorNode> getInlineNodesFromPosition(
      NodePosition begin, NodePosition end);

  EditorNode newNode({String? id, int? depth});

  NodePosition get beginPosition;

  NodePosition get endPosition;

  String get id => _id;

  String get text;
}

String get randomNodeId => _uuid.v1();

const _uuid = Uuid();

class NodeWithCursor<T extends NodePosition> {
  final EditorNode node;
  final SingleNodeCursor<T> cursor;

  NodeWithCursor(this.node, this.cursor);

  int get index => cursor.index;

  @override
  String toString() {
    return 'NodeWithCursor{node: $node, cursor: $cursor}';
  }
}

class EditingData<T extends NodePosition> {
  final EditingCursor<T> cursor;
  final EventType type;
  final NodesOperator operator;
  final dynamic extras;

  EditingData(this.cursor, this.type, this.operator, {this.extras});

  EditingData<E> as<E extends NodePosition>({NodesOperator? operator}) =>
      EditingData<E>(cursor.as<E>(), type, operator ?? this.operator,
          extras: extras);

  T get position => cursor.position;

  int get index => cursor.index;

  @override
  String toString() {
    return 'EditingData{position: $position, type: $type, extras: $extras}';
  }
}

class SelectingData<T extends NodePosition> {
  final SelectingNodeCursor<T> cursor;
  final EventType type;
  final NodesOperator operator;

  final dynamic extras;

  SelectingData(this.cursor, this.type, this.operator, {this.extras});

  T get left => cursor.left;

  T get right => cursor.right;

  int get index => cursor.index;

  SelectingData<E> as<E extends NodePosition>({NodesOperator? operator}) =>
      SelectingData<E>(cursor.as<E>(), type, operator ?? this.operator,
          extras: extras);

  @override
  String toString() {
    return 'SelectingData{cursor: $cursor, type: $type, extras: $extras}';
  }
}

enum EventType {
  typing,
  delete,
  increaseDepth,
  decreaseDepth,
  selectAll,
  newline,
  underline,
  bold,
  italic,
  lineThrough,
  link,
  code,
  paste,
}
