import '../../../../editor/extension/string.dart';
import '../../../../editor/extension/unmodifiable.dart';

import '../../../cursor/code_block.dart';
import '../../basic.dart';
import '../../../cursor/node_position.dart';
import '../../rich_text/rich_text.dart';
import '../code_block.dart';

NodeWithPosition deleteWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  if (p == node.beginPosition.copy(atEdge: false) || p == node.beginPosition) {
    return NodeWithPosition(
        node, SelectingPosition(node.beginPosition, node.endPosition));
  }
  final index = p.index;
  final lastIndex = index - 1;
  final codes = node.codes;
  if (p.offset == 0) {
    final code = codes[lastIndex] + codes[index];
    final newPosition = CodeBlockPosition(lastIndex, codes[lastIndex].length);
    return NodeWithPosition(
        node.from(codes.replaceMore(lastIndex, lastIndex + 2, [code])),
        EditingPosition(newPosition));
  } else {
    final codeWithOffset = codes[index].removeAt(p.offset);
    final newPosition =
        EditingPosition(CodeBlockPosition(index, codeWithOffset.offset));
    return NodeWithPosition(
        node.from(codes.replaceOne(index, [codeWithOffset.text])), newPosition);
  }
}

NodeWithPosition deleteWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  if (data.left == node.beginPosition && data.right == node.endPosition) {
    final newNode = RichTextNode.from([]);
    return NodeWithPosition(newNode, EditingPosition(newNode.beginPosition));
  }
  final newLeft = node.frontPartNode(data.left);
  final newRight = node.rearPartNode(data.right);
  final newNode = newLeft.merge(newRight);
  return NodeWithPosition(newNode, EditingPosition(newLeft.endPosition));
}
