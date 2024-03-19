import 'package:flutter/cupertino.dart';
import '../core/context.dart';
import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import '../shortcuts/arrows.dart';

@immutable
abstract class EditorNode<T extends NodePosition> {
  EditorNode({String? id})
      : _id = id ?? '${DateTime.now().millisecondsSinceEpoch}';

  final String _id;

  Map<String, dynamic> toJson();

  Widget build(EditorContext context, int index);

  EditorNode<T> frontPartNode(T end, {String? newId});

  EditorNode<T> rearPartNode(T begin, {String? newId});

  NodeWithPosition<T>? delete(T position);

  /// if cannot merge, this function will throw an exception [UnableToMergeException]
  EditorNode<T> merge(EditorNode other, {String? newId});

  EditorNode<T> getFromPosition(T begin, T end, {String? newId});


  T get beginPosition;

  T get endPosition;

  String get id => _id;
}

class NodeWithPosition<T extends NodePosition>{
  final EditorNode<T> node;
  final T position;

  NodeWithPosition(this.node, this.position);
}
