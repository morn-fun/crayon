import '../node/basic.dart';
import 'basic.dart';

class TypingRequiredOptionalMenuException implements MenuException {
  final NodeWithPosition nodeWithPosition;

  TypingRequiredOptionalMenuException(this.nodeWithPosition);

  String get message =>
      '${nodeWithPosition.node.runtimeType} required optional menu';
}