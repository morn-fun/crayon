import '../core/command_invoker.dart';
import '../core/controller.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import 'basic_command.dart';

class ModifyNode implements BasicCommand {
  final SingleNodeCursor cursor;
  final EditorNode node;

  ModifyNode(this.cursor, this.node);

  @override
  UpdateControllerOperation? run(RichEditorController controller) {
    return controller.update(Update(cursor.index, node, cursor));
  }

  @override
  String toString() {
    return 'ModifyNode{cursor: $cursor, node: $node}';
  }
}
