import '../core/command_invoker.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import 'basic.dart';

class MoveNode implements BasicCommand {
  final int from;
  final int to;

  MoveNode(this.from, this.to);

  @override
  UpdateControllerOperation? run(NodesOperator operator) =>
      operator.onOperation(MoveTo(from, to));

  @override
  String toString() {
    return 'MoveNode{from: $from, to: $to}';
  }
}

class MoveIntoNode implements BasicCommand {
  final MoveInto moveInto;

  MoveIntoNode(this.moveInto);

  @override
  UpdateControllerOperation? run(NodesOperator operator) =>
      operator.onOperation(moveInto);

  @override
  String toString() {
    return 'MoveIntoNode{moveInto: $moveInto}';
  }
}

class MoveOutNode implements BasicCommand {
  final MoveOut moveOut;

  MoveOutNode(this.moveOut);

  @override
  UpdateControllerOperation? run(NodesOperator operator) =>
      operator.onOperation(moveOut);

  @override
  String toString() {
    return 'MoveIntoNode{moveOut: $moveOut}';
  }
}

class MoveExchangeNode implements BasicCommand {
  final MoveExchange moveExchange;

  MoveExchangeNode(this.moveExchange);

  @override
  UpdateControllerOperation? run(NodesOperator operator) =>
      operator.onOperation(moveExchange);

  @override
  String toString() {
    return 'MoveIntoNode{moveExchange: $moveExchange}';
  }
}
