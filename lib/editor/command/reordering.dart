import '../core/command_invoker.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import 'basic.dart';

class MoveNode implements BasicCommand {
  final int from;
  final int to;

  MoveNode(this.from, this.to);

  @override
  UpdateControllerOperation? run(NodesOperator operator) {
    return operator.onOperation(MoveTo(from, to));
  }

  @override
  String toString() {
    return 'MoveNode{from: $from, to: $to}';
  }
}