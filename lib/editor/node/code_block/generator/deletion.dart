import '../../../../editor/extension/string.dart';
import '../../../../editor/extension/unmodifiable.dart';

import '../../../cursor/basic.dart';
import '../../../cursor/code_block.dart';
import '../../basic.dart';
import '../../rich_text/rich_text.dart';
import '../code_block.dart';

NodeWithCursor deleteWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final nodeIndex = data.index;
  if (p == node.beginPosition.copy(atEdge: false) || p == node.beginPosition) {
    return NodeWithCursor(node,
        SelectingNodeCursor(nodeIndex, node.beginPosition, node.endPosition));
  }
  final index = p.index;
  final lastIndex = index - 1;
  final codes = node.codes;
  if (p.offset == 0) {
    final code = codes[lastIndex] + codes[index];
    final newPosition = CodeBlockPosition(lastIndex, codes[lastIndex].length);
    return NodeWithCursor(
        node.from(codes.replaceMore(lastIndex, lastIndex + 2, [code])),
        EditingCursor(nodeIndex, newPosition));
  } else {
    final codeWithOffset = codes[index].removeAt(p.offset);
    return NodeWithCursor(
        node.from(codes.replaceOne(index, [codeWithOffset.text])),
        EditingCursor(
            nodeIndex, CodeBlockPosition(index, codeWithOffset.offset)));
  }
}

NodeWithCursor deleteWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  if (data.left == node.beginPosition && data.right == node.endPosition) {
    final newNode = RichTextNode.from([]);
    return NodeWithCursor(
        newNode, EditingCursor(data.index, newNode.beginPosition));
  }
  final newLeft = node.frontPartNode(data.left);
  final newRight = node.rearPartNode(data.right);
  final newNode = newLeft.merge(newRight);
  return NodeWithCursor(
      newNode, EditingCursor(data.index, data.left));
}
