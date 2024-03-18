import '../core/command_invoker.dart';
import '../core/controller.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import 'basic_command.dart';

class ModifyNode implements BasicCommand {
  final EditingCursor cursor;
  final EditorNode node;
  final bool record;

  ModifyNode(this.cursor, this.node, {this.record = true});

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    return controller.update(UpdateOne(cursor.index, node, cursor),
        record: record);
  }

  @override
  String toString() {
    return 'ModifyNode{record: $record, cursor: $cursor, node: $node}';
  }
}
