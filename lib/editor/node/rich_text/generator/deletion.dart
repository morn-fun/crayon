import '../../../cursor/rich_text.dart';
import '../../basic.dart';
import '../../../cursor/node_position.dart';
import '../rich_text_node.dart';

NodeWithPosition deleteRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  final newLeft = node.frontPartNode(data.left);
  final newRight = node.rearPartNode(data.right);
  final newNode = newLeft.merge(newRight);
  return NodeWithPosition(newNode, EditingPosition(newLeft.endPosition));
}
