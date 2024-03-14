import '../core/controller.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import 'basic_command.dart';

class ModifyNode implements BasicCommand {
  final EditingCursor oldCursor;
  final EditingCursor newCursor;
  final EditorNode node;

  ModifyNode(this.oldCursor, this.newCursor, this.node, {this.old});

  EditorNode? old;

  @override
  void execute(RichEditorController controller) {
    old ??= controller.getNode(newCursor.index)!;
    controller.update(UpdateData(node, newCursor));
  }

  @override
  void undo(RichEditorController controller) {
    controller.update(UpdateData(old!, oldCursor));
  }
}
