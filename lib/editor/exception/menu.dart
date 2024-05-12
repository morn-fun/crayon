import '../core/context.dart';
import '../node/basic.dart';
import 'basic.dart';

class TypingRequiredOptionalMenuException implements MenuException {
  final NodeWithPosition nodeWithPosition;
  final NodeContext context;

  TypingRequiredOptionalMenuException(this.nodeWithPosition, this.context);

  String get message =>
      '${nodeWithPosition.node.runtimeType}, context:${context.runtimeType} required optional menu';
}