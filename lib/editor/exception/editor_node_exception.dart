import '../cursor/basic_cursor.dart';
import '../shortcuts/arrows/arrows.dart';
import 'basic_exception.dart';

class UnableToMergeException implements EditorNodeException {
  final Type origin;
  final Type other;

  UnableToMergeException(this.origin, this.other);

  String get message => 'type:$origin cannot match type:$other!';

  @override
  String toString() {
    return 'DisableToMergeException{origin: $origin, other: $other}';
  }
}

class DeleteRequiresNewLineException implements EditorNodeException {
  final Type type;

  DeleteRequiresNewLineException(this.type);

  String get message => 'the $type is requiring a new line';

  @override
  String toString() {
    return 'DeleteRequiresNewLineException{type: $type}';
  }
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
