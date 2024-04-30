import '../core/command_invoker.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import 'basic.dart';

class ReplaceNode implements BasicCommand {
  final Replace replace;
  final bool record;

  ReplaceNode(this.replace, {this.record = true});

  @override
  UpdateControllerOperation? run(NodeContext nodeContext) {
    return nodeContext.replace(replace, record: record);
  }

  @override
  String toString() {
    return 'ReplaceNode{replace: $replace, record: $record}';
  }
}
