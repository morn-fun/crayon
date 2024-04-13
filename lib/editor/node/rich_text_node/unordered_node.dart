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
        return from([], id: newId ?? id);
      } else if (begin == beginPosition && end != endPosition) {
        return from([], id: newId ?? id);
      }
      return super.getFromPosition(begin, end, newId: newId ?? id, trim: trim);
    }
    return super.getFromPosition(begin, end, newId: newId ?? id, trim: trim);
  }

  @override
  Widget build(EditorContext context, int index) {
    return Builder(builder: (c) {
      final theme = Theme.of(c);
      return Row(
        children: [
          buildMarker(18, theme),
          Expanded(
              child: RichTextWidget(
            context,
            this,
            index,
          )),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    });
  }

  Container buildMarker(double height, ThemeData theme) {
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
