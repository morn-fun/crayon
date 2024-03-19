import 'basic_exception.dart';

class NoCommandException implements CommandException {
  final String operation;

  NoCommandException(this.operation);

  String get message => 'there is no command to $operation!';
}

class PerformCommandException implements CommandException {
  final Type type;
  final String reason;
  final Object e;

  PerformCommandException(this.type, this.reason, this.e);

  String get message => '$reason, execute command:$type error: $e';

  @override
  String toString() {
    return 'PerformCommandException{type: $type, e: $e}';
  }
}
