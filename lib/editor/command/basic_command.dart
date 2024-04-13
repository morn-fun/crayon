import '../core/command_invoker.dart';
import '../core/controller.dart';

abstract class BasicCommand {
  UpdateControllerOperation? run(RichEditorController controller);
}
