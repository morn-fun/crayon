import '../core/command_invoker.dart';
import '../core/controller.dart';
import 'basic_command.dart';

class ReplaceNode implements BasicCommand {
  final Replace replace;
  final bool record;

  ReplaceNode(this.replace, {this.record = true});

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    return controller.replace(replace, record: record);
  }

  @override
  String toString() {
    return 'ReplaceNode{replace: $replace, record: $record}';
  }
}
