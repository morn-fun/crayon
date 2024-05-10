import '../core/editor_controller.dart';
import '../node/rich_text/rich_text.dart';
import 'basic.dart';

BasicCursor? generateSelectingCursor(EditingCursor editingCursor, RichEditorController controller) {
  final oldCursor = controller.cursor;
  final index = editingCursor.index;
  final endPosition = editingCursor.position;
  BasicCursor? newCursor;
  if (oldCursor is EditingCursor) {
    final oldIndex = oldCursor.index;
    if (index == oldIndex) {
      newCursor = SelectingNodeCursor(index, oldCursor.position, endPosition);
    } else {
      newCursor = getSelectingNodesCursor(
          controller, oldIndex, index, oldCursor.position, endPosition);
    }
  } else if (oldCursor is SelectingNodeCursor) {
    final oldIndex = oldCursor.index;
    if (index == oldCursor.index) {
      newCursor = SelectingNodeCursor(index, oldCursor.begin, endPosition);
    } else {
      newCursor = getSelectingNodesCursor(
          controller, oldIndex, index, oldCursor.begin, endPosition);
    }
  } else if (oldCursor is SelectingNodesCursor) {
    if (oldCursor.beginIndex == index) {
      newCursor =
          SelectingNodeCursor(index, oldCursor.beginPosition, endPosition);
    } else {
      newCursor = getSelectingNodesCursor(controller, oldCursor.beginIndex,
          index, oldCursor.beginPosition, endPosition);
    }
  }
  return newCursor;
}

BasicCursor<NodePosition>? getSelectingNodesCursor(
    RichEditorController controller,
    int oldIndex,
    int newIndex,
    NodePosition oldPosition,
    NodePosition newPosition) {
  final oldNode = controller.getNode(oldIndex);
  final node = controller.getNode(newIndex);
  bool isOldNodeInLower = newIndex > oldIndex;

  BasicCursor newCursor;
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
