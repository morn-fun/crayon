import 'package:flutter/material.dart' hide RichText;

import '../../core/node_controller.dart';
import '../../widget/nodes/rich_text.dart';
import '../position_data.dart';
import 'special_newline_mixin.dart';
import 'rich_text_node.dart';
import 'rich_text_span.dart';

class UnorderedNode extends RichTextNode with SpecialNewlineMixin {
  UnorderedNode.from(super.spans, {super.id, super.depth}) : super.from();

  @override
  RichTextNode from(List<RichTextSpan> spans, {String? id, int? depth}) =>
      UnorderedNode.from(spans, id: id ?? this.id, depth: depth ?? this.depth);

  @override
  Widget build(
      NodeController controller, SingleNodePosition? position, dynamic extras) {
    return Builder(builder: (c) {
      final theme = Theme.of(c);
      return Row(
        children: [
          buildMarker(26, theme),
          Expanded(
              child: RichText(
            controller,
            this,
            position,
          )),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    });
  }

  Widget buildMarker(double height, ThemeData theme) {
    int remainder = depth % 4 + 1;
    final color = theme.textTheme.titleLarge?.color;
    late Decoration decoration;
    if (remainder == 1) {
      decoration = BoxDecoration(shape: BoxShape.circle, color: color);
    } else if (remainder == 2) {
      decoration = BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color ?? Colors.black));
    } else if (remainder == 3) {
      decoration = BoxDecoration(shape: BoxShape.rectangle, color: color);
    } else {
      decoration = BoxDecoration(
          shape: BoxShape.rectangle,
          border: Border.all(color: color ?? Colors.black));
    }
    return Container(
      width: 5,
      height: 5,
      margin: EdgeInsets.only(top: height / 2 - 2, right: 8),
      decoration: decoration,
    );
  }
}
