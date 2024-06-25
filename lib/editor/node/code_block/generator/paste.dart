import '../../../../editor/extension/unmodifiable.dart';

import '../../../cursor/basic.dart';
import '../../../cursor/code_block.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../code_block.dart';

NodeWithCursor pasteWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final nodes = data.extras;
  if (nodes is! List<EditorNode> || nodes.isEmpty) {
    throw NodeUnsupportedException(
        node.runtimeType, 'pasteWhileEditing', nodes);
  }
  final newCodes = <String>[];
  for (var n in nodes) {
    if (n is CodeBlockNode) {
      newCodes.addAll(n.codes);
    } else {
      newCodes.add(n.text.trim());
    }
  }
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
  return NodeWithCursor(newNode, EditingCursor(data.index, newPosition));
}

NodeWithCursor pasteWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final nodes = data.extras;
  final p = data.cursor;
  if (nodes is! List<EditorNode> || nodes.isEmpty) {
    throw NodeUnsupportedException(
        node.runtimeType, 'pasteWhileSelecting', nodes);
  }
  if (p.begin == node.beginPosition && p.end == node.endPosition) {
    throw PasteToCreateMoreNodesException(
        nodes, node.runtimeType, nodes.last.endPosition);
  }
  final newCodes = <String>[];
  for (var n in nodes) {
    if (n is CodeBlockNode) {
      newCodes.addAll(n.codes);
    } else {
      newCodes.add(n.text.trim());
    }
  }
  bool oneLine = newCodes.length == 1;
  final lastCodeLength = newCodes.last.length;
  final newPosition = CodeBlockPosition(p.left.index + newCodes.length - 1,
      oneLine ? p.left.offset + lastCodeLength : lastCodeLength);
  final newNode = node.replace(p.left, p.right, newCodes);
  return NodeWithCursor(newNode, EditingCursor(data.index, newPosition));
}
