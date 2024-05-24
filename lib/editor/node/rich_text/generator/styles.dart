import 'package:crayon/editor/cursor/basic.dart';

import '../../../cursor/rich_text.dart';
import '../../../shortcuts/styles.dart';
import '../../basic.dart';
import '../rich_text.dart';

NodeWithCursor styleRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node, String tag) {
  final left = data.left;
  final right = data.right;
  final styleExtra =
      data.extras is StyleExtra ? data.extras : StyleExtra(false, null);
  bool coverTag = !styleExtra.containsTag;
  final leftOffset = node.getOffset(left);
  final rightOffset = node.getOffset(right);
  final selectingNode = node.getFromPosition(left, right);
  bool needAddTag = coverTag;
  if (!coverTag) {
    for (var span in selectingNode.spans) {
      if (!span.tags.contains(tag)) {
        needAddTag = true;
        break;
      }
    }
  }
  final newSpans = needAddTag
      ? selectingNode.buildSpansByAddingTag(tag,
          attributes: styleExtra.attributes)
      : selectingNode.buildSpansByRemovingTag(tag,
          attributes: styleExtra.attributes);
  final newNode = node.replace(left, right, newSpans);
  final pLeft = newNode.getPositionByOffset(leftOffset);
  final pRight = newNode.getPositionByOffset(rightOffset);
  return NodeWithCursor(
      newNode, SelectingNodeCursor(data.index, pLeft, pRight));
}
