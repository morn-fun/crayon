import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../widget/rich_text_widget.dart';
import '../basic_node.dart';
import 'rich_text_node.dart';
import 'rich_text_span.dart';

abstract class HeadNode extends RichTextNode {
  HeadNode.empty({super.id, this.fontSize = 30}) : super.empty();

  HeadNode.from(super.spans, {super.id, this.fontSize = 30}) : super.from();

  final double fontSize;

  @override
  NodeWithPosition onEdit(EditingData data) {
    final d = data.as<RichTextNodePosition>();
    final type = d.type;
    if (type == EventType.newline) {
      final left = frontPartNode(d.position);
      final right = rearPartNode(d.position, newId: randomNodeId);
      throw NewlineRequiresNewSpecialNode(
          [left, RichTextNode.from(right.spans, id: right.id)],
          right.beginPosition);
    }
    return super.onEdit(data);
  }

  @override
  NodeWithPosition<NodePosition> onSelect(SelectingData<NodePosition> data) {
    final d = data.as<RichTextNodePosition>();
    final type = d.type;
    if (type == EventType.newline) {
      final left = frontPartNode(d.left);
      final right = rearPartNode(d.right, newId: randomNodeId);
      throw NewlineRequiresNewSpecialNode(
          [left, RichTextNode.from(right.spans, id: right.id)],
          right.beginPosition);
    } else if (type == EventType.delete) {}
    return super.onSelect(data);
  }

  @override
  TextSpan buildTextSpan({TextStyle? style}) =>
      super.buildTextSpan(style: TextStyle(fontSize: fontSize));

  @override
  TextSpan buildTextSpanWithCursor(BasicCursor<NodePosition> c, int index,
          {TextStyle? style}) =>
      super.buildTextSpanWithCursor(c, index,
          style: TextStyle(fontSize: fontSize));

  @override
  TextSpan selectingTextSpan(
          RichTextNodePosition begin, RichTextNodePosition end,
          {TextStyle? style}) =>
      super.selectingTextSpan(begin, end, style: TextStyle(fontSize: fontSize));

  @override
  Widget build(EditorContext context, int index) {
    return RichTextWidget(
      context,
      this,
      index,
      fontSize: fontSize,
    );
  }
}

class H1Node extends HeadNode {
  H1Node.empty({super.id}) : super.empty(fontSize: 30);

  H1Node.from(super.spans, {super.id}) : super.from(fontSize: 30);

  @override
  H1Node from(List<RichTextSpan> spans, {String? id}) =>
      H1Node.from(spans, id: id);
}

class H2Node extends HeadNode {
  H2Node.empty({super.id}) : super.empty(fontSize: 27);

  H2Node.from(super.spans, {super.id}) : super.from(fontSize: 27);

  @override
  H2Node from(List<RichTextSpan> spans, {String? id}) =>
      H2Node.from(spans, id: id);
}

class H3Node extends HeadNode {
  H3Node.empty({super.id}) : super.empty(fontSize: 24);

  H3Node.from(super.spans, {super.id}) : super.from(fontSize: 24);

  @override
  H3Node from(List<RichTextSpan> spans, {String? id}) =>
      H3Node.from(spans, id: id);
}