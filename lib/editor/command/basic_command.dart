import '../core/command_invoker.dart';
import '../core/controller.dart';

abstract class BasicCommand {
  UpdateControllerCommand? run(RichEditorController controller);
}
