import 'package:flutter/material.dart';

import '../cursor/basic.dart';
import '../node/basic.dart';
import '../node/rich_text/rich_text.dart';
import '../shortcuts/arrows/arrows.dart';
import 'basic.dart';

class UnableToMergeException implements EditorNodeException {
  final String origin;
  final String other;

  UnableToMergeException(this.origin, this.other);

  String get message => 'origin:$origin cannot match other:$other!';

  @override
  String toString() {
    return 'UnableToMergeException{origin: $origin, other: $other}';
  }
}

class DeleteRequiresNewLineException implements EditorNodeException {
  final NodePosition position;

  DeleteRequiresNewLineException(this.position);

  String get message => 'the $position is requiring a new line';

  @override
  String toString() {
    return 'DeleteRequiresNewLineException{position: $position}';
  }
}

class DeleteToChangeNodeException implements EditorNodeException {
  final EditorNode node;
  final NodePosition position;

  DeleteToChangeNodeException(this.node, this.position);

  String get message => 'the node is going to be as ${node.runtimeType}';
}

class NewlineRequiresNewNode implements EditorNodeException {
  final Type type;

  NewlineRequiresNewNode(this.type);

  String get message => 'the $type is requiring insert a new node';

  @override
  String toString() {
    return 'NewlineRequiresNewNode{type: $type}';
  }
}

class NewlineRequiresNewSpecialNode implements EditorNodeException {
  final List<EditorNode> newNodes;
  final NodePosition position;

  NewlineRequiresNewSpecialNode(this.newNodes, this.position);

  String get message => 'newline with new special node!';
}

class DeleteNotAllowedException implements EditorNodeException {
  final Type type;

  DeleteNotAllowedException(this.type);

  String get message => 'the $type node cannot be deleted anymore!';

  @override
  String toString() {
    return 'DeleteNotAllowedException{type: $type}';
  }
}

class NodePositionDifferentException implements EditorNodeException {
  final Type origin;
  final Type other;

  NodePositionDifferentException(this.origin, this.other);

  String get message => 'the origin:$origin is not same as other:$other';

  @override
  String toString() {
    return 'NodePositionDifferentException{origin: $origin, other: $other}';
  }
}

class NodePositionInvalidException implements EditorNodeException {
  final String reason;

  NodePositionInvalidException(this.reason);

  String get message => 'the node position is invalid, $reason';

  @override
  String toString() {
    return 'NodePositionInvalidException{reason: $reason}';
  }
}

class ArrowIsEndException implements EditorNodeException {
  final ArrowType type;
  final NodePosition position;

  ArrowIsEndException(this.type, this.position);

  String get message =>
      'the position $position with arrow $type is end in current node!';

  @override
  String toString() {
    return 'ArrowIsEndException{type: $type, position: $position}';
  }
}

class ArrowLeftBeginException implements EditorNodeException {
  final dynamic position;

  ArrowLeftBeginException(this.position);

  String get message =>
      'the position $position is in begin, cannot move to left any more!';
}

class ArrowRightEndException implements EditorNodeException {
  final dynamic position;

  ArrowRightEndException(this.position);

  String get message =>
      'the position $position is in end, cannot move to right any more!';
}

class ArrowUpTopException implements EditorNodeException {
  final dynamic position;
  final Offset offset;

  ArrowUpTopException(this.position, this.offset);

  String get message =>
      'the position $position with $offset is in top, cannot move up any more!';
}

class ArrowDownBottomException implements EditorNodeException {
  final dynamic position;
  final Offset offset;

  ArrowDownBottomException(this.position, this.offset);

  String get message =>
      'the position $position with $offset is in bottom, cannot move down any more!';
}

class PasteToCreateMoreNodesException implements EditorNodeException {
  final List<EditorNode> nodes;
  final Type source;
  final NodePosition position;

  PasteToCreateMoreNodesException(this.nodes, this.source, this.position);

  String get message => 'the $source cannot paste nodes!';
}

class TypingToChangeNodeException implements EditorNodeException {
  final RichTextNode old;
  final NodeWithCursor current;

  TypingToChangeNodeException(this.old, this.current);

  String get message =>
      'old node ${old.runtimeType} is going to be changed as ${current.node.runtimeType}';
}

class DepthNotAbleToIncreaseException implements EditorNodeException {
  final Type type;
  final int depth;

  DepthNotAbleToIncreaseException(this.type, this.depth);

  String get message => 'the node:$type depth:$depth cannot increase';
}

class DepthNeedDecreaseMoreException implements EditorNodeException {
  final Type type;
  final int depth;

  DepthNeedDecreaseMoreException(this.type, this.depth);

  String get message =>
      'the node:$type need decrease more same type node with depth:$depth';
}

class NodeNotFoundException implements EditorNodeException {
  final String id;

  NodeNotFoundException(this.id);

  String get message => '$runtimeType the node:$id not found';
}

class EmptyNodeToSelectAllException implements EditorNodeException {
  final String id;

  EmptyNodeToSelectAllException(this.id);

  String get message => 'the node:$id is empty, to select all';
}

class NodeUnsupportedException implements EditorNodeException {
  final Type type;
  final String operation;
  final dynamic extras;

  NodeUnsupportedException(this.type, this.operation, this.extras);

  String get message =>
      'the node $type not supported for $operation with $extras';
}

class TableIsEmptyException implements EditorNodeException {}
