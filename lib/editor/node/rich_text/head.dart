import 'package:flutter/material.dart' hide RichText;

import '../../core/context.dart';
import '../../cursor/basic.dart';
import '../../cursor/rich_text.dart';
import '../../exception/editor_node.dart';
import '../../widget/nodes/rich_text.dart';
import '../basic.dart';
import 'rich_text.dart';
import 'rich_text_span.dart';

abstract class HeadNode extends RichTextNode {
  HeadNode.from(super.spans, {super.id, this.fontSize = 30, super.depth})
      : super.from();

  final double fontSize;

  @override
  NodeWithPosition onEdit(EditingData data) {
    final d = data.as<RichTextNodePosition>();
    final type = d.type;
    if (type == EventType.newline) {
      final left = frontPartNode(d.position);
      final right = rearPartNode(d.position, newId: randomNodeId);
      throw NewlineRequiresNewSpecialNode([
        left,
        RichTextNode.from(right.spans, id: right.id, depth: right.depth)
      ], right.beginPosition);
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
      throw NewlineRequiresNewSpecialNode([
        left,
        RichTextNode.from(right.spans, id: right.id, depth: right.depth)
      ], right.beginPosition);
    }
    return super.onSelect(data);
  }

  @override
  TextSpan buildTextSpan() => TextSpan(
      children: List.generate(
          spans.length,
          (index) => spans[index].buildSpan(
              style: TextStyle(fontSize: fontSize, color: Colors.black))));

  @override
  Widget build(NodeContext context, NodeBuildParam param, BuildContext c) {
    return RichTextWidget(
      context,
      this,
      param,
      fontSize: fontSize,
    );
  }
}

class H1Node extends HeadNode {
  H1Node.from(super.spans, {super.id, super.depth}) : super.from(fontSize: 30);

  @override
  H1Node from(List<RichTextSpan> spans, {String? id, int? depth}) =>
      H1Node.from(spans, id: id ?? this.id, depth: depth ?? this.depth);
}

class H2Node extends HeadNode {
  H2Node.from(super.spans, {super.id, super.depth}) : super.from(fontSize: 27);

  @override
  H2Node from(List<RichTextSpan> spans, {String? id, int? depth}) =>
      H2Node.from(spans, id: id ?? this.id, depth: depth ?? this.depth);
}

class H3Node extends HeadNode {
  H3Node.from(super.spans, {super.id, super.depth}) : super.from(fontSize: 24);

  @override
  H3Node from(List<RichTextSpan> spans, {String? id, int? depth}) =>
      H3Node.from(spans, id: id ?? this.id, depth: depth ?? this.depth);
}
