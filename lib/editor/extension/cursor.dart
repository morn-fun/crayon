import '../cursor/basic.dart';
import '../node/basic.dart';
import '../cursor/node_position.dart';

extension CursorExtension on BasicCursor {
  SelectingPosition? getSelectingPosition(int index, EditorNode node) {
    final cursor = this;
    if (cursor is EditingCursor) return null;
    if (cursor is SelectingNodeCursor) {
      if (cursor.index != index) return null;
      return SelectingPosition(cursor.begin, cursor.end);
    } else if (cursor is SelectingNodesCursor) {
      if (!cursor.contains(index)) return null;
      if (index == cursor.left.index) {
        return SelectingPosition(cursor.left.position, node.endPosition);
      } else if (index == cursor.right.index) {
        return SelectingPosition(node.beginPosition, cursor.right.position);
      } else {
        return SelectingPosition(node.beginPosition, node.endPosition);
      }
    }
    return null;
  }

  SingleNodePosition? getSingleNodePosition(int index, EditorNode node) {
    final cursor = this;
    if (cursor is EditingCursor) {
      if (cursor.index != index) return null;
      return EditingPosition(cursor.position);
    }
    return getSelectingPosition(index, node);
  }
}
