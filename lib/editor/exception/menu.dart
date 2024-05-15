import '../core/context.dart';
import '../node/basic.dart';
import 'basic.dart';

class TypingRequiredOptionalMenuException implements MenuException {
  final NodeWithCursor nodeWithCursor;
  final NodeContext context;

  TypingRequiredOptionalMenuException(this.nodeWithCursor, this.context);

  String get message =>
      '${nodeWithCursor.node.runtimeType}, context:${context.runtimeType} required optional menu';
}