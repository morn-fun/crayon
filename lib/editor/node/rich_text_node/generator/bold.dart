import '../../../cursor/rich_text_cursor.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../rich_text_node.dart';
import '../rich_text_span.dart';

NodeWithPosition boldRichTextNodeWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node) {
  final position = data.position;
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
  return NodeWithPosition(newNode,
      EditingPosition(newNode.getPositionByOffset(offset, trim: false)));
}

NodeWithPosition boldRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  final left = data.left;
  final right = data.right;
  final leftOffset = node.getOffset(left);
  final rightOffset = node.getOffset(right);
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
  return NodeWithPosition(
      newNode,
      SelectingPosition(newNode.getPositionByOffset(leftOffset, trim: false),
          newNode.getPositionByOffset(rightOffset, trim: false)));
}
