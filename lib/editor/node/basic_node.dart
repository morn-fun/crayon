import 'package:flutter/cupertino.dart';
import '../core/context.dart';
import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import 'position_data.dart';

@immutable
abstract class EditorNode {
  EditorNode({String? id})
      : _id = id ?? '${DateTime.now().millisecondsSinceEpoch}';

  final String _id;

  Map<String, dynamic> toJson();

  Widget build(EditorContext context, int index);

  /// if the [end] position is same to [beginPosition], you should return a empty RichTextNode
  EditorNode frontPartNode(NodePosition end, {String? newId});

  /// if the [begin] position is same to [endPosition], you should return a empty RichTextNode
  EditorNode rearPartNode(NodePosition begin, {String? newId});

  NodeWithPosition onEdit(EditingData data);

  NodeWithPosition onSelect(SelectingData data);

  /// if cannot merge, this function will throw an exception [UnableToMergeException]
  EditorNode merge(EditorNode other, {String? newId});

  EditorNode getFromPosition(NodePosition begin, NodePosition end,
      {String? newId});

  NodePosition get beginPosition;

  NodePosition get endPosition;

  String get id => _id;
}

class NodeWithPosition<T extends NodePosition> {
  final EditorNode node;
  final SingleNodePosition<T> position;

  NodeWithPosition(this.node, this.position);

  SingleNodeCursor<T> toCursor(int index) => position.toCursor(index);
}

class EditingData<T extends NodePosition> {
  final T position;
  final EventType type;
  final dynamic extras;

  EditingData(this.position, this.type, {this.extras});

  EditingData<E> as<E extends NodePosition>() =>
      EditingData<E>(position as E, type, extras: extras);

  @override
  String toString() {
    return 'EditingData{position: $position, type: $type, extras: $extras}';
  }
}

class SelectingData<T extends NodePosition> {
  final SelectingPosition<T> position;
  final EventType type;
  final dynamic extras;

  SelectingData(this.position, this.type, {this.extras});

  T get left => position.left;

  T get right => position.right;

  SelectingData<E> as<E extends NodePosition>() =>
      SelectingData<E>(position.as<E>(), type, extras: extras);

  @override
  String toString() {
    return 'SelectingData{position: $position, type: $type, extras: $extras}';
  }
}

enum EventType {
  typing,
  delete,
  enter,
  selectAll,
  newline,
  underline,
  bold,
  italic,
  lineThrough,
}
