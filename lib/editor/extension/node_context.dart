import 'package:crayon/editor/core/context.dart';

import '../cursor/basic.dart';
import '../node/basic.dart';
import '../node/rich_text/rich_text.dart';
import '../node/rich_text/rich_text_span.dart';

extension NodeContextExtension on NodeContext {
  List<EditorNode> listNeedRefreshDepth(int startIndex, int startDepth) {
    final newList = <EditorNode>[];
    int index = startIndex + 1;
    int depth = startDepth;
    while (index < nodeLength) {
      var node = getNode(index);
      if (node.depth - depth > 1) {
        depth = depth + 1;
        newList.add(node.newNode(depth: depth));
      } else {
        break;
      }
      index++;
    }
    return newList;
  }

  Set<String> tagIntersection() {
    final c = cursor;
    var basicSets = RichTextTag.values.map((e) => e.name).toSet();
    if (c is EditingCursor) return {};
    if (c is SelectingNodeCursor) {
      basicSets = _intersection(getNode(c.index), c.left, c.right, basicSets);
    } else if (c is SelectingNodesCursor) {
      final left = c.left;
      final right = c.right;
      int l = left.index;
      int r = right.index;
      while (l <= r && basicSets.isNotEmpty) {
        final node = getNode(l);
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
      if (node is! RichTextNode) continue;
      int j = 0;
      while (j < node.spans.length && basicSets.isNotEmpty) {
        final span = node.spans[j];
        basicSets = basicSets.intersection(span.tags);
        j++;
      }
      i++;
    }
    return basicSets;
  }

  bool textNotEmptyAt(int index) {
    bool contains = false;
    final c = cursor;
    if (c is SelectingNodeCursor) {
      contains = c.index == index;
      if (contains) {
        var node = getNode(index);
        node = node.getFromPosition(c.begin, c.end);
        if (node.text.isEmpty) contains = false;
      }
    } else if (c is SelectingNodesCursor) {
      contains = c.contains(index);
      if (contains) {
        final left = c.left;
        final right = c.right;
        int l = left.index, r = right.index;
        while (l <= r) {
          var node = getNode(l);
          if (l == left.index) {
            node = node.getFromPosition(left.position, node.endPosition);
          } else if (l == right.index) {
            node = node.getFromPosition(node.beginPosition, right.position);
          }
          if (node.text.isNotEmpty) break;
          l++;
        }
        if (l > r) contains = false;
      }
    }
    return contains;
  }
}
