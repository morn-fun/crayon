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

  String get message => 'the $type node cannot be deleted anymore!';

  @override
  String toString() {
    return 'DeleteRequiresNewLineException{type: $type}';
  }
}

