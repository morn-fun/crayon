import '../cursor/basic.dart';
import '../node/basic.dart';
import '../node/rich_text/rich_text.dart';
import '../node/rich_text/rich_text_span.dart';

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

  Set<String> tagIntersection(List<EditorNode> nodes) {
    final c = this;
    var basicSets = RichTextTag.values.map((e) => e.name).toSet();
    if (c is EditingCursor) return {};
    if (c is SelectingNodeCursor) {
      basicSets = _intersection(nodes[c.index], c.left, c.right, basicSets);
    } else if (c is SelectingNodesCursor) {
      final left = c.left;
      final right = c.right;
      int l = left.index;
      int r = right.index;
      while (l <= r && basicSets.isNotEmpty) {
        final node = nodes[l];
        if (l == left.index) {
          basicSets =
              _intersection(node, left.position, node.endPosition, basicSets);
        } else if (l == r) {
          basicSets = _intersection(
              node, node.beginPosition, right.position, basicSets);
        } else {
          basicSets = _intersection(
              node, node.beginPosition, node.endPosition, basicSets);
        }
        l++;
      }
    }
    return basicSets;
  }

  Set<String> _intersection(EditorNode node, NodePosition begin,
      NodePosition end, Set<String> basicSets) {
    final list = node.getInlineNodesFromPosition(begin, end);
    int i = 0;
    while (i < list.length && basicSets.isNotEmpty) {
      final node = list[i];
      if (node is RichTextNode) {
        int j = 0;
        while (j < node.spans.length && basicSets.isNotEmpty) {
          final span = node.spans[j];
          basicSets = basicSets.intersection(span.tags);
          j++;
        }
      }
      i++;
    }
    return basicSets;
  }
}
