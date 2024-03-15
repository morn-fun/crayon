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
  void run(RichEditorController controller) {
    controller.update(UpdateOne(node, cursor, cursor.index), record: record);
  }
}
