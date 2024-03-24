import '../../core/command_invoker.dart';
import '../../core/controller.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../node/rich_text_node/rich_text_node.dart';
import '../../node/rich_text_node/rich_text_span.dart';
import '../basic_command.dart';

class BoldWhileEditingRichTextNode implements BasicCommand {
  final EditingCursor<RichTextNodePosition> cursor;
  final RichTextNode node;

  BoldWhileEditingRichTextNode(this.cursor, this.node);

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    final position = cursor.position;
    final offset = node.getOffset(position);
    final currentSpan = node.getSpan(position.index);
    final tag = RichTextTag.strong.name;
    bool needAddTag = !currentSpan.tags.contains(tag);
    RichTextNode newNode;
    if (needAddTag) {
      newNode = node.insertByPosition(
          position, RichTextSpan(tags: {RichTextTag.strong.name}));
    } else {
      newNode = node.insertByPosition(position, RichTextSpan());
    }
    final newCursor = EditingCursor(
        cursor.index, newNode.getPositionByOffset(offset, trim: false));
    return controller.update(UpdateOne(cursor.index, newNode, newCursor));
  }
}

class BoldWhileSelectingRichTextNode implements BasicCommand {
  final SelectingNodeCursor<RichTextNodePosition> cursor;
  final RichTextNode node;

  BoldWhileSelectingRichTextNode(this.cursor, this.node);

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    final left = cursor.left;
    final right = cursor.right;
    final leftOffset = node.getOffset(cursor.left);
    final rightOffset = node.getOffset(cursor.right);
    final selectingNode = node.getFromPosition(left, right, trim: true);
    bool needAddTag = false;
    final tag = RichTextTag.strong.name;
    for (var span in selectingNode.spans) {
      if (!span.tags.contains(tag)) {
        needAddTag = true;
        break;
      }
    }
    final newSpans = needAddTag
        ? selectingNode.buildSpansByAddingTag(tag)
        : selectingNode.buildSpansByRemovingTag(tag);
    final newNode = node.replace(left, right, newSpans);
    SelectingNodeCursor newCursor = SelectingNodeCursor(
        cursor.index,
        newNode.getPositionByOffset(leftOffset, trim: false),
        newNode.getPositionByOffset(rightOffset, trim: false));
    return controller.update(UpdateOne(cursor.index, newNode, newCursor));
  }
}
