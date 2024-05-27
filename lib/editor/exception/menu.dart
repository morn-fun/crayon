import '../core/context.dart';
import '../node/basic.dart';
import 'basic.dart';

class TypingRequiredOptionalMenuException implements MenuException {
  final NodeWithCursor nodeWithCursor;
  final NodesOperator operator;

  TypingRequiredOptionalMenuException(this.nodeWithCursor, this.operator);

  String get message =>
      '${nodeWithCursor.node.runtimeType}, operator:${operator.runtimeType} required optional menu';
}