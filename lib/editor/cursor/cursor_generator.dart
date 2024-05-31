import '../extension/node_context.dart';
import '../node/rich_text/rich_text.dart';
import 'basic.dart';

BasicCursor? generateSelectingCursor(
  EditingCursor editingCursor,
  EditingCursor panStartCursor,
  NodeGetter nodeGetter,
) {
  final oldCursor = panStartCursor;
  final index = editingCursor.index;
  final endPosition = editingCursor.position;
  BasicCursor? newCursor;
  final oldIndex = oldCursor.index;
  if (index == oldIndex) {
    newCursor = SelectingNodeCursor(index, oldCursor.position, endPosition);
  } else {
    newCursor = getSelectingNodesCursor(
        nodeGetter, oldIndex, index, oldCursor.position, endPosition);
  }
  return newCursor;
}

SelectingNodesCursor<NodePosition>? getSelectingNodesCursor(
    NodeGetter nodeGetter,
    int oldIndex,
    int newIndex,
    NodePosition oldPosition,
    NodePosition newPosition) {
  final oldNode = nodeGetter.call(oldIndex);
  final node = nodeGetter.call(newIndex);
  bool isOldNodeInLower = newIndex > oldIndex;

  SelectingNodesCursor newCursor;
  if (oldNode is RichTextNode && node is RichTextNode) {
    newCursor = SelectingNodesCursor(EditingCursor(oldIndex, oldPosition),
        EditingCursor(newIndex, newPosition));
  } else if (oldNode is RichTextNode && node is! RichTextNode) {
    newCursor = SelectingNodesCursor(
        EditingCursor(oldIndex, oldPosition),
        EditingCursor(newIndex,
            isOldNodeInLower ? node.endPosition : node.beginPosition));
  } else if (oldNode is! RichTextNode && node is RichTextNode) {
    newCursor = SelectingNodesCursor(
        EditingCursor(oldIndex,
            isOldNodeInLower ? oldNode.beginPosition : oldNode.endPosition),
        EditingCursor(newIndex, newPosition));
  } else {
    newCursor = SelectingNodesCursor(
        EditingCursor(oldIndex,
            isOldNodeInLower ? oldNode.beginPosition : oldNode.endPosition),
        EditingCursor(newIndex,
            isOldNodeInLower ? node.endPosition : node.beginPosition));
  }
  return newCursor;
}
