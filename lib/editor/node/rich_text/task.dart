import 'package:flutter/material.dart' hide RichText;

import '../../core/context.dart';
import '../../widget/nodes/rich_text.dart';
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
  Widget build(NodesOperator operator, NodeBuildParam param, BuildContext c) {
    return Builder(builder: (c) {
      return Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: Checkbox(
                value: done,
                onChanged: (v) {
                  operator.onNode(from(spans, done: !done), param.index);
                }),
          ),
          Expanded(child: RichTextWidget(operator, this, param)),
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
