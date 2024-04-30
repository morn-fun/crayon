import '../../../cursor/code_block.dart';
import '../../basic.dart';
import '../../../cursor/node_position.dart';
import '../code_block.dart';

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
  final notEdgeBegin = begin.copy(atEdge: false);
  final notEdgeEnd = end.copy(atEdge: false);
  if (left == notEdgeBegin && right == notEdgeEnd) {
    return NodeWithPosition(
        node, SelectingPosition(node.beginPosition, node.endPosition));
  } else {
    return NodeWithPosition(node, SelectingPosition(notEdgeBegin, notEdgeEnd));
  }
}
