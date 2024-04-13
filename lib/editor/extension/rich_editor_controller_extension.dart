
import '../core/controller.dart';
import '../node/basic_node.dart';

extension RichEditorControllerExtension on RichEditorController {
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
}
