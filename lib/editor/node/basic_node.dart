import 'package:flutter/cupertino.dart';
import '../core/context.dart';
import '../core/controller.dart';
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

  EditorNode frontPartNode(NodePosition end, {String? newId});

  EditorNode rearPartNode(NodePosition begin, {String? newId});

  NodeWithPosition? delete(NodePosition position);

  void handleEventWhileEditing(
      EditingEvent<NodePosition> event, EditorContext context);

  void handleEventWhileSelecting(
      SelectingNodeEvent<NodePosition> event, EditorContext context);

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
