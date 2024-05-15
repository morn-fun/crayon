import '../../../cursor/basic.dart';
import '../../../cursor/code_block.dart';
import '../../basic.dart';
import '../code_block.dart';

NodeWithCursor selectAllWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final code = node.codes[p.index];
  if (node.codes.length == 1 && node.codes.first.isEmpty) {
    return NodeWithCursor(node,
        SelectingNodeCursor(data.index, node.beginPosition, node.endPosition));
  }
  return NodeWithCursor(
      node,
      SelectingNodeCursor(data.index, CodeBlockPosition(p.index, 0),
          CodeBlockPosition(p.index, code.length)));
}

NodeWithCursor selectAllWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.cursor;
  final left = p.left;
  final right = p.right;
  final begin = node.beginPosition;
  final end = node.endPosition;
  final notEdgeBegin = begin.copy(atEdge: false);
  final notEdgeEnd = end.copy(atEdge: false);
  if (left == notEdgeBegin && right == notEdgeEnd) {
    return NodeWithCursor(node,
        SelectingNodeCursor(data.index, node.beginPosition, node.endPosition));
  } else {
    return NodeWithCursor(
        node, SelectingNodeCursor(data.index, notEdgeBegin, notEdgeEnd));
  }
}
