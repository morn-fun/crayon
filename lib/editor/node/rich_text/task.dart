import 'package:flutter/material.dart' hide RichText;

import '../../core/node_controller.dart';
import '../../widget/nodes/rich_text.dart';
import '../../cursor/node_position.dart';
import 'rich_text.dart';
import 'rich_text_span.dart';
import 'special_newline_mixin.dart';

class TodoNode extends RichTextNode with SpecialNewlineMixin {
  final bool done;

  TodoNode.from(
    super.spans, {
    super.id,
    super.depth,
    this.done = false,
  }) : super.from();

  @override
  TodoNode from(List<RichTextSpan> spans,
          {String? id, int? depth, bool? done}) =>
      TodoNode.from(spans,
          done: done ?? this.done,
          id: id ?? this.id,
          depth: depth ?? this.depth);

  @override
  Widget build(
      NodeController controller, SingleNodePosition? position, dynamic extras) {
    return Builder(builder: (c) {
      return Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: Checkbox(
                value: done,
                onChanged: (v) {
                  controller.updateNode(from(spans, done: !done));
                }),
          ),
          Expanded(
              child: RichTextWidget(
            controller,
            this,
            position,
          )),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    });
  }

  @override
  TextSpan buildTextSpan() {
    final doneStyle =
        TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough);
    return TextSpan(
        children: List.generate(spans.length,
            (index) => spans[index].buildSpan(style: done ? doneStyle : null)));
  }
}
