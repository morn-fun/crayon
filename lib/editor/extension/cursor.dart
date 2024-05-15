import '../cursor/basic.dart';
import '../node/basic.dart';

extension CursorExtension on BasicCursor {
  SelectingNodeCursor? getSelectingPosition(int index, EditorNode node) {
    final cursor = this;
    if (cursor is EditingCursor) return null;
    if (cursor is SelectingNodeCursor) {
      if (cursor.index != index) return null;
      return cursor;
    } else if (cursor is SelectingNodesCursor) {
      if (!cursor.contains(index)) return null;
      if (index == cursor.left.index) {
        return SelectingNodeCursor(
            index, cursor.left.position, node.endPosition);
      } else if (index == cursor.right.index) {
        return SelectingNodeCursor(
            index, node.beginPosition, cursor.right.position);
      } else {
        return SelectingNodeCursor(index, node.beginPosition, node.endPosition);
      }
    }
    return null;
  }

  SingleNodeCursor? getSingleNodeCursor(int index, EditorNode node) {
    final cursor = this;
    if (cursor is EditingCursor) {
      if (cursor.index != index) return null;
      return cursor;
    }
    return getSelectingPosition(index, node);
  }
}
