import 'package:flutter/services.dart';

import '../../../../editor/extension/string.dart';
import '../../../../editor/extension/unmodifiable.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/code_block.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../code_block.dart';

NodeWithCursor typingWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final delta = data.extras as TextEditingDelta;
  final p = data.position;
  final index = p.index;
  final code = node.codes[index];
  if (delta is TextEditingDeltaInsertion) {
    final text = delta.textInserted;
    final newCode = code.insert(p.offset, text);
    final newNode = node.from(node.codes.replaceOne(index, [newCode]));
    return NodeWithCursor(
        newNode,
        EditingCursor(
            data.index, CodeBlockPosition(index, p.offset + text.length)));
  } else if (delta is TextEditingDeltaReplacement) {
    final text = delta.replacementText;
    final range = delta.replacedRange;
    final correctRange = TextRange(start: p.offset - range.end, end: p.offset);
    final newCode = code.replace(correctRange, text);
    final newNode = node.from(node.codes.replaceOne(index, [newCode]));
    return NodeWithCursor(
        newNode,
        EditingCursor(data.index,
            CodeBlockPosition(index, correctRange.start + text.length)));
  } else if (delta is TextEditingDeltaDeletion) {
    final offset = p.offset;
    final range = delta.deletedRange;
    final deltaPosition = range.end - range.start;
    final correctRange = TextRange(start: offset - deltaPosition, end: offset);
    final newCode = code.remove(correctRange);
    final newNode = node.from(node.codes.replaceOne(index, [newCode]));
    return NodeWithCursor(newNode,
        EditingCursor(data.index, CodeBlockPosition(index, correctRange.start)));
  }
  throw NodeUnsupportedException(node.runtimeType, 'typingWhileEditing', p);
}

NodeWithCursor typingWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.cursor;
  final newNode = node.replace(p.left, p.right, []);
  return typingWhileEditing(
      EditingData(p.leftCursor, EventType.typing, data.context,
          extras: data.extras),
      newNode);
}
