import 'package:flutter/services.dart';
import '../../../../editor/extension/string.dart';

import '../../../core/context.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/rich_text.dart';
import '../../../exception/editor_node.dart';
import '../../../exception/menu.dart';
import '../../basic.dart';
import '../head.dart';
import '../ordered.dart';
import '../quote.dart';
import '../rich_text.dart';
import '../task.dart';
import '../unordered.dart';

NodeWithCursor typingRichTextNodeWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node) {
  final delta = data.extras as TextEditingDelta;
  if (delta is TextEditingDeltaInsertion) {
    final position = data.position;
    final text = delta.textInserted;
    checkNeedChangeNodeTyp(text, node, position, data.index);
    final span = node.getSpan(position.index);
    final newNode = node.update(position.index,
        span.copy(text: (v) => v.insert(position.offset, text)));
    final newPosition =
        RichTextNodePosition(position.index, position.offset + text.length);
    checkNeedShowSelectingMenu(
        text, newNode, newPosition, data.context, data.index);
    return NodeWithCursor(newNode, EditingCursor(data.index, newPosition));
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
    return NodeWithCursor(
        newNode,
        EditingCursor(data.index,
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
    return NodeWithCursor(
        newNode,
        EditingCursor(
            data.index, RichTextNodePosition(index, correctRange.start)));
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'typingRichTextNodeWhileEditing', data);
}

NodeWithCursor typingRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  final newLeft = node.frontPartNode(data.left);
  final newRight = node.rearPartNode(data.right);
  final nodeAfterMerge = newLeft.merge(newRight);
  try {
    return typingRichTextNodeWhileEditing(
        EditingData(EditingCursor(data.index, newLeft.endPosition),
            EventType.typing, data.context,
            extras: data.extras),
        nodeAfterMerge);
  } on TypingRequiredOptionalMenuException catch (e) {
    return e.nodeWithCursor;
  }
}

void checkNeedChangeNodeTyp(
    String text, RichTextNode node, RichTextNodePosition position, int index) {
  if (text != ' ') return;
  final frontText = node.frontPartNode(position).text;
  RegExp orderedRegExp = RegExp(r'^(\+)?\d+(\.)$');
  if (orderedRegExp.allMatches(frontText).length == 1) {
    final rearNode = node.rearPartNode(position);
    final newNode = OrderedNode.from(rearNode.spans,
        id: rearNode.id, depth: rearNode.depth);
    throw TypingToChangeNodeException(newNode,
        NodeWithCursor(newNode, newNode.beginPosition.toCursor(index)));
  }
  final generator = _string2generator[frontText];
  if (generator != null) {
    final newNode = generator.call(node.rearPartNode(position));
    if (node.runtimeType.toString() == newNode.runtimeType.toString()) return;
    throw TypingToChangeNodeException(newNode,
        NodeWithCursor(newNode, newNode.beginPosition.toCursor(index)));
  }
}

void checkNeedShowSelectingMenu(String text, RichTextNode node,
    RichTextNodePosition position, NodeContext context, int index) {
  final frontText = node.frontPartNode(position).text;
  if (frontText == '/') {
    throw TypingRequiredOptionalMenuException(
        NodeWithCursor(node, position.toCursor(index)), context);
  }
}

typedef RichTextNodeGenerator = RichTextNode Function(RichTextNode node);

final Map<String, RichTextNodeGenerator> _string2generator = {
  '-': (n) => UnorderedNode.from(n.spans, id: n.id, depth: n.depth),
  '#': (n) => H1Node.from(n.spans, id: n.id, depth: n.depth),
  '##': (n) => H2Node.from(n.spans, id: n.id, depth: n.depth),
  '###': (n) => H3Node.from(n.spans, id: n.id, depth: n.depth),
  '>': (n) => QuoteNode.from(n.spans, id: n.id, depth: n.depth),
  '[ ]': (n) => TodoNode.from(n.spans, id: n.id, depth: n.depth),
  '[x]': (n) => TodoNode.from(n.spans, id: n.id, depth: n.depth, done: true),
};
