import 'package:flutter/services.dart';
import '../../../editor/extension/string_extension.dart';

import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../node/rich_text_node/rich_text_node.dart';
import '../basic_command.dart';
import '../modification.dart';

BasicCommand? generateRichTextCommandWhileEditing(
    EditingCursor<RichTextNodePosition> cursor,
    RichTextNode node,
    TextEditingDelta delta) {
  if (delta is TextEditingDeltaInsertion) {
    final position = cursor.position;
    final text = delta.textInserted;
    final span = node.getSpan(position.index);
    final newNode = node.update(position.index,
        span.copy(text: (v) => v.insert(position.offset, text)));
    return ModifyNode(
        EditingCursor(
            cursor.index,
            RichTextNodePosition(
                position.index, position.offset + text.length)),
        newNode);
  } else if (delta is TextEditingDeltaReplacement) {
    final position = cursor.position;
    final text = delta.replacementText;
    final range = delta.replacedRange;
    final index = position.index;
    final span = node.getSpan(index);
    final offset = position.offset;
    final correctRange = TextRange(start: offset - range.end, end: offset);
    final newNode = node.update(
        index, span.copy(text: (v) => v.replace(correctRange, text)));
    return ModifyNode(
      EditingCursor(cursor.index,
          RichTextNodePosition(index, correctRange.start + text.length)),
      newNode,
    );
  } else if (delta is TextEditingDeltaDeletion) {
    final position = cursor.position;
    final index = position.index;
    final span = node.getSpan(index);
    final offset = position.offset - span.offset;
    final range = delta.deletedRange;
    final deltaPosition = range.end - range.start;
    final correctRange = TextRange(start: offset - deltaPosition, end: offset);
    final newNode =
        node.update(index, span.copy(text: (v) => v.remove(correctRange)));
    return ModifyNode(
      EditingCursor(index, RichTextNodePosition(index, correctRange.start)),
      newNode,
    );
  }
  return null;
}

BasicCommand? generateRichTextCommandWhileSelecting(
    SelectingNodeCursor<RichTextNodePosition> cursor,
    RichTextNode node,
    TextEditingDelta delta) {
  final index = cursor.index;
  final newLeft = node.frontPartNode(cursor.left);
  final newRight = node.rearPartNode(cursor.right);
  final nodeAfterMerge = newLeft.merge(newRight);
  final newCursor = EditingCursor(index, newLeft.endPosition);
  return generateRichTextCommandWhileEditing(newCursor, nodeAfterMerge, delta);
}