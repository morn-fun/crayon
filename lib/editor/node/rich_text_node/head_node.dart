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
  TextSpan buildTextSpan({TextStyle? style}) =>
      super.buildTextSpan(style: TextStyle(fontSize: fontSize));

  @override
  Widget build(
      NodeController controller, SingleNodePosition? position, dynamic extras) {
    return RichText(
      controller,
      this,
      position,
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
