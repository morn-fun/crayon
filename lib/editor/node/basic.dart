import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import '../core/context.dart';
import '../core/listener_collection.dart';
import '../cursor/basic.dart';
import '../exception/editor_node.dart';
import '../cursor/node_position.dart';

@immutable
abstract class EditorNode {
  EditorNode({String? id, this.depth = 0}) : _id = id ?? randomNodeId;

  final String _id;

  final int depth;

  Map<String, dynamic> toJson();

  Widget build(NodeContext context, NodeBuildParam param, BuildContext c);

  /// if the [end] position is same to [beginPosition], you should return a empty RichTextNode
  EditorNode frontPartNode(NodePosition end, {String? newId});

  /// if the [begin] position is same to [endPosition], you should return a empty RichTextNode
  EditorNode rearPartNode(NodePosition begin, {String? newId});

  EditorNode getFromPosition(NodePosition begin, NodePosition end,
      {String? newId});

  NodeWithPosition onEdit(EditingData data);

  NodeWithPosition onSelect(SelectingData data);

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

class NodeWithPosition<T extends NodePosition> {
  final EditorNode node;
  final SingleNodePosition<T> position;

  NodeWithPosition(this.node, this.position);

  SingleNodeCursor<T> toCursor(int index) => position.toCursor(index);
}

class EditingData<T extends NodePosition> {
  final T position;
  final EventType type;
  final NodeContext context;
  final dynamic extras;

  EditingData(this.position, this.type, this.context, {this.extras});

  EditingData<E> as<E extends NodePosition>({NodeContext? context}) =>
      EditingData<E>(position as E, type, context ?? this.context,
          extras: extras);

  ListenerCollection get listeners => context.listeners;

  @override
  String toString() {
    return 'EditingData{position: $position, type: $type, extras: $extras}';
  }
}

class SelectingData<T extends NodePosition> {
  final SelectingPosition<T> position;
  final EventType type;
  final NodeContext context;

  final dynamic extras;

  SelectingData(this.position, this.type, this.context, {this.extras});

  T get left => position.left;

  T get right => position.right;

  ListenerCollection get listeners => context.listeners;

  SelectingData<E> as<E extends NodePosition>({NodeContext? context}) =>
      SelectingData<E>(position.as<E>(), type, context ?? this.context,
          extras: extras);

  @override
  String toString() {
    return 'SelectingData{position: $position, type: $type, extras: $extras}';
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
