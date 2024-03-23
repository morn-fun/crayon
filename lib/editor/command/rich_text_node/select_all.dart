import '../../core/command_invoker.dart';
import '../../core/controller.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../node/rich_text_node/rich_text_node.dart';
import '../basic_command.dart';

class SelectAllWhileEditingRichTextNode implements BasicCommand {
  final EditingCursor<RichTextNodePosition> cursor;
  final RichTextNode node;

  SelectAllWhileEditingRichTextNode(this.cursor, this.node);

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    controller.updateCursor(SelectingNodeCursor(
        cursor.index, node.beginPosition, node.endPosition));
    return null;
  }
}

class SelectAllWhileSelectingRichTextNode implements BasicCommand {
  final SelectingNodeCursor<RichTextNodePosition> cursor;
  final RichTextNode node;

  SelectAllWhileSelectingRichTextNode(this.cursor, this.node);

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    controller.updateCursor(SelectingNodeCursor(
        cursor.index, node.beginPosition, node.endPosition));
    return null;
  }
}
