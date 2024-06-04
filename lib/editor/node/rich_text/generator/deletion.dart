import '../../../../editor/cursor/basic.dart';
import '../../../cursor/rich_text.dart';
import '../../basic.dart';
import '../rich_text.dart';

NodeWithCursor deleteRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  final newLeft = node.frontPartNode(data.left);
  final newRight = node.rearPartNode(data.right);
  final newNode = newLeft.merge(newRight);
  return NodeWithCursor(
      newNode, EditingCursor(data.index, newLeft.endPosition));
}
