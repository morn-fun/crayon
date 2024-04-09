import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../core/controller.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../widget/rich_text_widget.dart';
import '../basic_node.dart';
import 'rich_text_node.dart';
import 'rich_text_span.dart';

class OrderedNode extends RichTextNode {
  OrderedNode.from(super.spans, {super.id, super.depth}) : super.from();

  @override
  RichTextNode from(List<RichTextSpan> spans, {String? id, int? depth}) =>
      OrderedNode.from(spans, id: id, depth: depth ?? this.depth);

  @override
  NodeWithPosition onEdit(EditingData data) {
    final d = data.as<RichTextNodePosition>();
    final type = d.type;
    if (type == EventType.newline) {
      if (beginPosition == endPosition) {
        throw NewlineRequiresNewSpecialNode(
            [RichTextNode.from([], id: id, depth: depth)], beginPosition);
      }
      final left = frontPartNode(d.position);
      final right = rearPartNode(d.position, newId: randomNodeId);
      throw NewlineRequiresNewSpecialNode([left, right], right.beginPosition);
    } else if (type == EventType.delete) {
      if (d.position == beginPosition) {
        throw DeleteToChangeNodeException(
            RichTextNode.from(spans, id: id, depth: depth), beginPosition);
      }
    }
    return super.onEdit(data);
  }

  @override
  NodeWithPosition<NodePosition> onSelect(SelectingData<NodePosition> data) {
    final d = data.as<RichTextNodePosition>();
    final type = data.type;
    if (type == EventType.newline) {
      final left = frontPartNode(d.left);
      final right = rearPartNode(d.right, newId: randomNodeId);
      throw NewlineRequiresNewSpecialNode([left, right], right.beginPosition);
    }
    return super.onSelect(data);
  }

  @override
  RichTextNode getFromPosition(
      covariant RichTextNodePosition begin, covariant RichTextNodePosition end,
      {String? newId, bool trim = false}) {
    if (begin == end) {
      if (begin != beginPosition && end == endPosition) {
        return from([], id: newId);
      } else if (begin == beginPosition && end != endPosition) {
        return from([], id: newId);
      }
      return super.getFromPosition(begin, end, newId: newId, trim: trim);
    }
    return super.getFromPosition(begin, end, newId: newId, trim: trim);
  }

  @override
  Widget build(EditorContext c, int index) {
    return RichTextWidget(
      c,
      this,
      index,
      painterBuilder: (painter, context, child) {
        final size = 14.0;
        final theme = Theme.of(context);
        return Row(
          children: [
            Text(
              '${generateOrderedNumber(getIndex(index, c.controller) + 1, depth)}. ',
              style: TextStyle(
                  fontSize: size,
                  color: theme.textTheme.displayMedium?.color),
            ),
            Expanded(child: child),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        );
      },
    );
  }

  int getIndex(int indexInController, RichEditorController controller) {
    if (indexInController <= 0) return 0;
    int lastIndex = indexInController - 1;
    final node = controller.getNode(lastIndex);
    if (node is! OrderedNode) return 0;
    if (node.depth != depth) return 0;
    return getIndex(indexInController - 1, controller) + 1;
  }
}

String generateOrderedNumber(int index, int depth) {
  int remainder = depth % 3 + 1;
  if (remainder == 1) {
    return '$index';
  } else if (remainder == 2) {
    return generateRomanNumeral(index);
  } else {
    return generateEnglishLetter(index);
  }
}

String generateRomanNumeral(int index) {
  if (index < 1) {
    throw Exception('Index must be greater than 0');
  }

  String result = '';
  for (final entry in romanNumerals.entries) {
    while (index >= entry.key) {
      result += entry.value;
      index -= entry.key;
    }
  }
  return result;
}

String generateEnglishLetter(int index) {
  if (index < 1) {
    throw Exception('Index must be greater than 0');
  }
  int alphabetLength = 26;
  String sequence = '';
  while (index > 0) {
    int charIndex = (index - 1) % alphabetLength;
    sequence = String.fromCharCode('a'.codeUnitAt(0) + charIndex) + sequence;
    index = (index - 1) ~/ alphabetLength;
  }
  return sequence;
}

const Map<int, String> romanNumerals = {
  1000: 'M',
  900: 'CM',
  500: 'D',
  400: 'CD',
  100: 'C',
  90: 'XC',
  50: 'L',
  40: 'XL',
  10: 'X',
  9: 'IX',
  5: 'V',
  4: 'IV',
  1: 'I'
};
