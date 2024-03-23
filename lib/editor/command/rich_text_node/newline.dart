import '../../core/command_invoker.dart';
import '../../core/controller.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../node/rich_text_node/rich_text_node.dart';
import '../basic_command.dart';

class InsertNewlineWhileEditingRichTextNode implements BasicCommand {
  final EditingCursor<RichTextNodePosition> cursor;
  final RichTextNode node;

  InsertNewlineWhileEditingRichTextNode(this.cursor, this.node);


  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    int index = cursor.index;
    final current = controller.getNode(index);
    final left = current.frontPartNode(cursor.position);
    final right = current.rearPartNode(cursor.position,
        newId: '${DateTime.now().millisecondsSinceEpoch}');
    return controller.replace(Replace(index, index + 1, [left, right],
        EditingCursor(index + 1, right.beginPosition)));
  }
}

class InsertNewlineWhileSelectingRichTextNode implements BasicCommand {
  final SelectingNodeCursor<RichTextNodePosition> cursor;
  final RichTextNode node;

  InsertNewlineWhileSelectingRichTextNode(this.cursor, this.node);

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    int index = cursor.index;
    final current = controller.getNode(index);
    final left = current.frontPartNode(cursor.left);
    final right = current.rearPartNode(cursor.right,
        newId: '${DateTime.now().millisecondsSinceEpoch}');
    return controller.replace(Replace(index, index + 1, [left, right],
        EditingCursor(index + 1, right.beginPosition)));
  }
}
