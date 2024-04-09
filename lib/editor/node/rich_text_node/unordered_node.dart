import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../widget/rich_text_widget.dart';
import '../basic_node.dart';
import 'rich_text_node.dart';
import 'rich_text_span.dart';

class UnorderedNode extends RichTextNode {
  UnorderedNode.from(super.spans, {super.id, super.depth}) : super.from();

  @override
  RichTextNode from(List<RichTextSpan> spans, {String? id, int? depth}) =>
      UnorderedNode.from(spans, id: id, depth: depth ?? this.depth);

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
        return UnorderedNode.from([], id: newId);
      } else if (begin == beginPosition && end != endPosition) {
        return UnorderedNode.from([], id: newId);
      }
      return super.getFromPosition(begin, end, newId: newId, trim: trim);
    }
    return super.getFromPosition(begin, end, newId: newId, trim: trim);
  }

  @override
  Widget build(EditorContext context, int index) {
    return RichTextWidget(
      context,
      this,
      index,
      painterBuilder: (painter, context, child) {
        final lines = painter.computeLineMetrics();
        final height = lines.isEmpty ? 16 : lines.first.height;
        final theme = Theme.of(context);
        return Row(
          children: [
            Container(
              width: 5,
              height: 5,
              margin: EdgeInsets.only(top: height / 2 - 2, left: 4, right: 4),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.textTheme.titleLarge?.color),
            ),
            Expanded(child: child),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        );
      },
    );
  }
}
