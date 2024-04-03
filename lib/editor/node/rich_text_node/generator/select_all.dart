import '../../../cursor/rich_text_cursor.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../rich_text_node.dart';

NodeWithPosition selectAllRichTextNodeWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node) {
  return NodeWithPosition(node, SelectingPosition(node.beginPosition, node.endPosition));
}

NodeWithPosition selectAllRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  return NodeWithPosition(node, SelectingPosition(node.beginPosition, node.endPosition));
}
