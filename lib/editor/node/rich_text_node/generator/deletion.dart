import '../../../cursor/rich_text_cursor.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../rich_text_node.dart';

NodeWithPosition deleteRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  final newLeft = node.frontPartNode(data.left);
  final newRight = node.rearPartNode(data.right);
  final newNode = newLeft.merge(newRight);
  return NodeWithPosition(newNode, EditingPosition(newLeft.endPosition));
}
