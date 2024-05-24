import '../core/command_invoker.dart';
import '../core/context.dart';


abstract class BasicCommand {
  UpdateControllerOperation? run(NodesOperator context);
}

typedef OperationInvoker = UpdateControllerOperation? Function(UpdateControllerOperation o);