import 'package:flutter/cupertino.dart';
import '../command/basic_command.dart';
import '../core/context.dart';
import '../core/events.dart';
import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';

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

  NodeWithPosition? delete(NodePosition position);

  BasicCommand? handleEventWhileEditing(EditingEvent<NodePosition> event);

  BasicCommand? handleEventWhileSelecting(
      SelectingNodeEvent<NodePosition> event);

  /// if cannot merge, this function will throw an exception [UnableToMergeException]
  EditorNode merge(EditorNode other, {String? newId});

  EditorNode getFromPosition(NodePosition begin, NodePosition end,
      {String? newId});

  NodePosition get beginPosition;

  NodePosition get endPosition;

  String get id => _id;
}

class NodeWithPosition {
  final EditorNode node;
  final NodePosition position;

  NodeWithPosition(this.node, this.position);
}
