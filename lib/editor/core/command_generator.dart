import 'package:flutter/services.dart';

import '../command/basic_command.dart';
import '../command/modification.dart';
import '../cursor/basic_cursor.dart';
import '../cursor/rich_text_cursor.dart';
import '../node/rich_text_node/rich_text_node.dart';
import '../extension/string_extension.dart';
import 'controller.dart';
import 'logger.dart';

BasicCommand? generateCommand(
    TextEditingDelta delta, RichEditorController controller) {
  if (delta is TextEditingDeltaInsertion) {
    return _generateFromInsertion(delta, controller);
  } else if (delta is TextEditingDeltaReplacement) {
    return _generateFromReplacement(delta, controller);
  } else if (delta is TextEditingDeltaDeletion) {
    return _generateFromDeletion(delta, controller);
  }
  return null;
}

BasicCommand? _generateFromInsertion(
    TextEditingDeltaInsertion delta, RichEditorController controller) {
  final cursor = controller.cursor;
  if (cursor is EditingCursor) {
    final node = controller.getNode(cursor.index)!;
    if (node is RichTextNode) {
      final position = cursor.position as RichTextNodePosition;
      final text = delta.textInserted;
      final span = node.getSpan(position.index);
      final offset = position.offset - span.offset;
      final newNode = node.update(
          position.index, span.copy(text: (v) => v.insert(offset, text)));
      return ModifyNode(
          EditingCursor(
              cursor.index,
              RichTextNodePosition(
                  position.index, position.offset + text.length)),
          newNode);
    }
  } else if (cursor is SelectingNodeCursor) {
  } else if (cursor is SelectingNodesCursor) {}
  return null;
}

BasicCommand? _generateFromReplacement(
    TextEditingDeltaReplacement delta, RichEditorController controller) {
  final cursor = controller.cursor;
  if (cursor is EditingCursor) {
    final node = controller.getNode(cursor.index)!;
    if (node is RichTextNode) {
      final position = cursor.position as RichTextNodePosition;
      final text = delta.replacementText;
      final range = delta.replacedRange;
      final index = position.index;
      final span = node.getSpan(index);
      final offset = position.offset - span.offset;
      final correctRange = TextRange(start: offset - range.end, end: offset);
      final newNode = node.update(
          index, span.copy(text: (v) => v.replace(correctRange, text)));
      return ModifyNode(
        EditingCursor(cursor.index,
            RichTextNodePosition(index, correctRange.start + text.length)),
        newNode,
      );
    }
  } else if (cursor is SelectingNodeCursor) {
  } else if (cursor is SelectingNodesCursor) {}
  return null;
}

BasicCommand? _generateFromDeletion(
    TextEditingDeltaDeletion delta, RichEditorController controller) {
  final cursor = controller.cursor as EditingCursor;
  final node = controller.getNode(cursor.index)!;
  if (node is RichTextNode) {
    final position = cursor.position as RichTextNodePosition;
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
