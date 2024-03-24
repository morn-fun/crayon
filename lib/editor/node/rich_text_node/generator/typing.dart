import 'package:flutter/services.dart';
import '../../../../editor/extension/string_extension.dart';

import '../../../cursor/rich_text_cursor.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../rich_text_node.dart';

NodeWithPosition typingRichTextNodeWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node) {
  final delta = data.extras as TextEditingDelta;
  if (delta is TextEditingDeltaInsertion) {
    final position = data.position;
    final text = delta.textInserted;
    final span = node.getSpan(position.index);
    final newNode = node.update(position.index,
        span.copy(text: (v) => v.insert(position.offset, text)));
    return NodeWithPosition(
        newNode,
        EditingPosition(RichTextNodePosition(
            position.index, position.offset + text.length)));
  } else if (delta is TextEditingDeltaReplacement) {
    final position = data.position;
    final text = delta.replacementText;
    final range = delta.replacedRange;
    final index = position.index;
    final span = node.getSpan(index);
    final offset = position.offset;
    final correctRange = TextRange(start: offset - range.end, end: offset);
    final newNode = node.update(
        index, span.copy(text: (v) => v.replace(correctRange, text)));
    return NodeWithPosition(
        newNode,
        EditingPosition(
            RichTextNodePosition(index, correctRange.start + text.length)));
  } else if (delta is TextEditingDeltaDeletion) {
    final position = data.position;
    final index = position.index;
    final span = node.getSpan(index);
    final offset = position.offset - span.offset;
    final range = delta.deletedRange;
    final deltaPosition = range.end - range.start;
    final correctRange = TextRange(start: offset - deltaPosition, end: offset);
    final newNode =
        node.update(index, span.copy(text: (v) => v.remove(correctRange)));
    return NodeWithPosition(newNode,
        EditingPosition(RichTextNodePosition(index, correctRange.start)));
  }
  return NodeWithPosition(node, EditingPosition(data.position));
}

NodeWithPosition typingRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  final newLeft = node.frontPartNode(data.left);
  final newRight = node.rearPartNode(data.right);
  final nodeAfterMerge = newLeft.merge(newRight);
  return typingRichTextNodeWhileEditing(
      EditingData(newLeft.endPosition, EventType.typing, extras: data.extras),
      nodeAfterMerge);
}
