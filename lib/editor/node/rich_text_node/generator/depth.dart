import '../../../cursor/rich_text_cursor.dart';
import '../../../exception/editor_node_exception.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../rich_text_node.dart';

NodeWithPosition increaseDepthWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node) {
  int lastDepth = data.extras is int ? data.extras : 0;
  int depth = node.depth;
  if (lastDepth < depth) {
    throw DepthNotAbleToIncreaseException(node.runtimeType, depth);
  }
  return NodeWithPosition(
      node.newNode(depth: depth + 1), EditingPosition(data.position));
}

NodeWithPosition increaseDepthWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  int lastDepth = data.extras is int ? data.extras : 0;
  int depth = node.depth;
  if (lastDepth < depth) {
    throw DepthNotAbleToIncreaseException(node.runtimeType, depth);
  }
  return NodeWithPosition(node.newNode(depth: depth + 1), data.position);
}