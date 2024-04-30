import '../../../../editor/extension/unmodifiable.dart';

import '../../../cursor/code_block.dart';
import '../../basic.dart';
import '../../../cursor/node_position.dart';
import '../code_block.dart';

NodeWithPosition pasteWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final nodes = data.extras;
  if (nodes is! List<EditorNode> || nodes.isEmpty) {
    return NodeWithPosition(node, EditingPosition(data.position));
  }
  final newCodes = nodes.map((e) => e.text).toList();
  final p = data.position;
  final codes = node.codes;
  final code = codes[p.index];
  final leftCode = code.substring(0, p.offset);
  final rightCode = code.substring(p.offset, code.length);
  final lastOffset = newCodes.last.length;
  newCodes[0] = leftCode + newCodes.first;
  newCodes[newCodes.length - 1] = newCodes.last + rightCode;
  final newNode = node.from(codes.replaceOne(p.index, newCodes));
  final newOffset = newCodes.length == 1 ? p.offset + lastOffset : lastOffset;
  final newPosition =
      CodeBlockPosition(p.index + newCodes.length - 1, newOffset);
  return NodeWithPosition(newNode, EditingPosition(newPosition));
}

NodeWithPosition pasteWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final nodes = data.extras;
  final p = data.position;
  if (nodes is! List<EditorNode> || nodes.isEmpty) {
    final newNode = node.replace(p.left, p.right, []);
    return NodeWithPosition(newNode, EditingPosition(p.left));
  }
  final newCodes = nodes.map((e) => e.text).toList();
  bool oneLine = newCodes.length == 1;
  final lastCodeLength = newCodes.last.length;
  final newPosition = CodeBlockPosition(p.left.index + newCodes.length - 1,
      oneLine ? p.left.offset + lastCodeLength : lastCodeLength);
  final newNode = node.replace(p.left, p.right, newCodes);
  return NodeWithPosition(newNode, EditingPosition(newPosition));
}
