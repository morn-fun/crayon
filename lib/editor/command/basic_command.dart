import '../core/command_invoker.dart';
import '../core/editor_controller.dart';

abstract class BasicCommand {
  UpdateControllerOperation? run(RichEditorController controller);
}
