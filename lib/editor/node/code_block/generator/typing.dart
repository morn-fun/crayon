import 'package:flutter/services.dart';

import '../../../../editor/extension/string.dart';
import '../../../../editor/extension/unmodifiable.dart';
import '../../../cursor/code_block.dart';
import '../../basic.dart';
import '../../../cursor/node_position.dart';
import '../code_block.dart';

NodeWithPosition typingWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final delta = data.extras as TextEditingDelta;
  final p = data.position;
  final index = p.index;
  final code = node.codes[index];
  if (delta is TextEditingDeltaInsertion) {
    final text = delta.textInserted;
    final newCode = code.insert(p.offset, text);
    final newNode = node.from(node.codes.replaceOne(index, [newCode]));
    final newPosition =
        EditingPosition(CodeBlockPosition(index, p.offset + text.length));
    return NodeWithPosition(newNode, newPosition);
  } else if (delta is TextEditingDeltaReplacement) {
    final text = delta.replacementText;
    final range = delta.replacedRange;
    final correctRange = TextRange(start: p.offset - range.end, end: p.offset);
    final newCode = code.replace(correctRange, text);
    final newNode = node.from(node.codes.replaceOne(index, [newCode]));
    return NodeWithPosition(
        newNode,
        EditingPosition(
            CodeBlockPosition(index, correctRange.start + text.length)));
  } else if (delta is TextEditingDeltaDeletion) {
    final offset = p.offset;
    final range = delta.deletedRange;
    final deltaPosition = range.end - range.start;
    final correctRange = TextRange(start: offset - deltaPosition, end: offset);
    final newCode = code.remove(correctRange);
    final newNode = node.from(node.codes.replaceOne(index, [newCode]));
    return NodeWithPosition(
        newNode, EditingPosition(CodeBlockPosition(index, correctRange.start)));
  }
  return NodeWithPosition(node, EditingPosition(data.position));
}

NodeWithPosition typingWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final newNode = node.replace(p.left, p.right, []);
  return typingWhileEditing(
      EditingData(p.left, EventType.typing, data.context,
          extras: data.extras),
      newNode);
}
