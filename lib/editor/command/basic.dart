import '../core/command_invoker.dart';
import '../core/context.dart';


abstract class BasicCommand {
  UpdateControllerOperation? run(NodeContext context);
}

typedef OperationInvoker = UpdateControllerOperation? Function(UpdateControllerOperation o);