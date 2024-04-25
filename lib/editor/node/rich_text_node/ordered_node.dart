import 'package:flutter/material.dart' hide RichText;
import '../../core/node_controller.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../widget/nodes/rich_text.dart';
import '../basic_node.dart';
import '../position_data.dart';
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
  Widget build(
      NodeController controller, SingleNodePosition? position, dynamic extras) {
    final size = 14.0;
    return Builder(builder: (c) {
      final theme = Theme.of(c);
      return Row(
        children: [
          Text(
            '${generateOrderedNumber(getIndex(extras as int, controller) + 1, depth)}. ',
            style: TextStyle(
                fontSize: size, color: theme.textTheme.displayMedium?.color),
          ),
          Expanded(child: RichText(controller, this, position)),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    });
  }

  int getIndex(int i, NodeController controller) {
    if (i <= 0) return 0;
    int lastIndex = i - 1;
    final node = controller.getNode(lastIndex);
    int nodeDepth = node.depth;
    if (nodeDepth > depth) {
      return getIndex(lastIndex, controller);
    } else if (nodeDepth < depth) {
      return 0;
    } else {
      if (node is! OrderedNode) return 0;
      return getIndex(lastIndex, controller) + 1;
    }
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
