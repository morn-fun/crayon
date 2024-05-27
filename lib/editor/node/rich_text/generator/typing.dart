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
  final v = data.extras;
  if (v is TextEditingValue) {
    final position = data.position,
        index = position.index,
        text = v.text,
        oldOffset = position.offset,
        valueOffset = v.selection.baseOffset,
        span = node.getSpan(index);
    checkNeedChangeNodeTyp(text, node, position, data.index);
    final newNode =
        node.update(index, span.copy(text: (v) => v.insert(oldOffset, text)));
    final newPosition = RichTextNodePosition(index, oldOffset + valueOffset);
    checkNeedShowSelectingMenu(newNode, newPosition, data.operator, data.index);
    return NodeWithCursor(newNode, EditingCursor(data.index, newPosition));
  }
  throw NodeUnsupportedException(
      node.runtimeType, 'typingRichTextNodeWhileEditing', data);
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
  final generator = string2generator[frontText];
  if (generator != null) {
    final newNode = generator.call(node.rearPartNode(position));
    if (node.runtimeType.toString() == newNode.runtimeType.toString()) return;
    throw TypingToChangeNodeException(newNode,
        NodeWithCursor(newNode, newNode.beginPosition.toCursor(index)));
  }
}

void checkNeedShowSelectingMenu(RichTextNode node,
    RichTextNodePosition position, NodesOperator operator, int index) {
  final frontText = node.frontPartNode(position).text;
  if (frontText == '/') {
    throw TypingRequiredOptionalMenuException(
        NodeWithCursor(node, position.toCursor(index)), operator);
  }
}

typedef RichTextNodeGenerator = RichTextNode Function(RichTextNode node);

final Map<String, RichTextNodeGenerator> string2generator = {
  '-': (n) => UnorderedNode.from(n.spans, id: n.id, depth: n.depth),
  '#': (n) => H1Node.from(n.spans, id: n.id, depth: n.depth),
  '##': (n) => H2Node.from(n.spans, id: n.id, depth: n.depth),
  '###': (n) => H3Node.from(n.spans, id: n.id, depth: n.depth),
  '>': (n) => QuoteNode.from(n.spans, id: n.id, depth: n.depth),
  '[ ]': (n) => TodoNode.from(n.spans, id: n.id, depth: n.depth),
  '[x]': (n) => TodoNode.from(n.spans, id: n.id, depth: n.depth, done: true),
};
