import 'package:flutter/material.dart' hide RichText;
import '../../core/context.dart';
import '../../widget/nodes/rich_text.dart';
import 'special_newline_mixin.dart';
import 'rich_text.dart';
import 'rich_text_span.dart';

class OrderedNode extends RichTextNode with SpecialNewlineMixin {
  OrderedNode.from(super.spans, {super.id, super.depth}) : super.from();

  @override
  RichTextNode from(List<RichTextSpan> spans, {String? id, int? depth}) =>
      OrderedNode.from(spans, id: id ?? this.id, depth: depth ?? this.depth);

  @override
  Widget build(NodesOperator operator, NodeBuildParam param, BuildContext c) {
    final size = 14.0;
    return Builder(builder: (c) {
      final theme = Theme.of(c);
      return Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${generateOrderedNumber(getIndex(param.index, operator) + 1, depth)}. ',
              style: TextStyle(
                  fontSize: size, color: theme.textTheme.displayMedium?.color),
            ),
          ),
          Expanded(child: RichTextWidget(operator, this, param)),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    });
  }

  int getIndex(int i, NodesOperator operator) {
    if (i <= 0) return 0;
    int lastIndex = i - 1;
    final node = operator.getNode(lastIndex);
    int nodeDepth = node.depth;
    if (nodeDepth > depth) {
      return getIndex(lastIndex, operator);
    } else if (nodeDepth < depth) {
      return 0;
    } else {
      if (node is! OrderedNode) return 0;
      return getIndex(lastIndex, operator) + 1;
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
