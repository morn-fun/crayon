import 'package:flutter/material.dart' hide RichText;

import '../../core/node_controller.dart';
import '../../widget/nodes/rich_text.dart';
import '../../cursor/node_position.dart';
import 'rich_text.dart';
import 'rich_text_span.dart';
import 'special_newline_mixin.dart';

class QuoteNode extends RichTextNode with SpecialNewlineMixin {
  QuoteNode.from(super.spans, {super.id, super.depth}) : super.from();

  @override
  QuoteNode from(List<RichTextSpan> spans, {String? id, int? depth}) =>
      QuoteNode.from(spans, id: id ?? this.id, depth: depth ?? this.depth);

  @override
  Widget build(
      NodeController controller, SingleNodePosition? position, dynamic extras) {
    return Builder(builder: (c) {
      final theme = Theme.of(c);
      return Container(
        decoration: BoxDecoration(
            border:
                Border(left: BorderSide(color: theme.hoverColor, width: 4))),
        padding: EdgeInsets.only(left: 4),
        child: RichText(controller, this, position),
      );
    });
  }
}
