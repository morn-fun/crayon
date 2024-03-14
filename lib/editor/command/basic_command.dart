import '../core/controller.dart';

abstract class BasicCommand {
  void execute(RichEditorController controller);

  void undo(RichEditorController controller);
}
