import '../../../cursor/rich_text.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../rich_text.dart';

NodeWithCursor increaseDepthWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node) {
  int lastDepth = data.extras is int ? data.extras : 0;
  int depth = node.depth;
  if (lastDepth < depth) {
    throw NodeUnsupportedException(
        node.runtimeType,
        'increaseDepthWhileEditing with depth $lastDepth small than $depth',
        depth);
  }
  return NodeWithCursor(node.newNode(depth: depth + 1), data.cursor);
}

NodeWithCursor increaseDepthWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  int lastDepth = data.extras is int ? data.extras : 0;
  int depth = node.depth;
  if (lastDepth < depth) {
    throw NodeUnsupportedException(
        node.runtimeType,
        'increaseDepthWhileEditing with depth $lastDepth small than $depth',
        depth);
  }
  return NodeWithCursor(node.newNode(depth: depth + 1), data.cursor);
}
