import '../../../cursor/code_block_cursor.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../code_block_node.dart';

NodeWithPosition selectAllWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final code = node.codes[p.index];
  if (node.codes.length == 1 && node.codes.first.isEmpty) {
    return NodeWithPosition(
        node, SelectingPosition(node.beginPosition, node.endPosition));
  }
  return NodeWithPosition(
      node,
      SelectingPosition(CodeBlockPosition(p.index, 0),
          CodeBlockPosition(p.index, code.length)));
}

NodeWithPosition selectAllWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final left = p.left;
  final right = p.right;
  final begin = node.beginPosition;
  final end = node.endPosition;
  final notEdgeBegin = begin.copy(inEdge: false);
  final notEdgeEnd = end.copy(inEdge: false);
  if (left == notEdgeBegin && right == notEdgeEnd) {
    return NodeWithPosition(
        node, SelectingPosition(node.beginPosition, node.endPosition));
  } else {
    return NodeWithPosition(node, SelectingPosition(notEdgeBegin, notEdgeEnd));
  }
}
