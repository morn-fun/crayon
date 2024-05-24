import '../command/modification.dart';
import '../core/context.dart';
import '../cursor/basic.dart';
import '../node/basic.dart';
import '../shortcuts/arrows/arrows.dart';

extension NodeContextExtension on NodesOperator {
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

  void onArrowAccept(AcceptArrowData data) => listeners.onArrowAccept(data);

  int get nodeLength => nodes.length;

  void onNodeWithCursor(NodeWithCursor p) {
    execute(ModifyNode(p));
  }
}

typedef NodeGetter = EditorNode Function(int index);
