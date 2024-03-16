import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:pre_editor/editor/cursor/basic_cursor.dart';
import '../../core/context.dart';
import '../../core/copier.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../widget/rich_text_widget.dart';
import '../basic_node.dart';
import 'rich_text_span.dart';

class RichTextNode extends EditorNode<RichTextNodePosition> {
  ///there must be at least one span in [spans]
  final UnmodifiableListView<RichTextSpan> spans;

  RichTextNode._(List<RichTextSpan> spans, {super.id})
      : spans = _buildInitSpans(spans);

  RichTextNode.empty({super.id}) : spans = _buildInitSpans([]);

  RichTextNode.from(List<RichTextSpan> spans) : spans = _buildInitSpans(spans);

  static UnmodifiableListView<RichTextSpan> _buildInitSpans(
      List<RichTextSpan> spans) {
    if (spans.isEmpty) return UnmodifiableListView([RichTextSpan()]);
    return UnmodifiableListView(spans);
  }

  TextSpan get textSpan => TextSpan(
      children:
          List.generate(spans.length, (index) => spans[index].buildSpan()));

  TextSpan selectingTextSpan(
      RichTextNodePosition begin, RichTextNodePosition end) {
    RichTextNodePosition left = begin.lowerThan(end) ? begin : end;
    RichTextNodePosition right = begin.lowerThan(end) ? end : begin;
    final textSpans = <InlineSpan>[];
    for (var i = 0; i < spans.length; ++i) {
      var span = spans[i];
      if (i < left.index || i > right.index) {
        textSpans.add(span.buildSpan());
        continue;
      }
      if (i > left.index || i < right.index) {
        textSpans.add(span.buildSpan());
        continue;
      }
      if (left.index == right.index) {
        textSpans.addAll(span.buildSelectingSpan(left.offset, right.offset));
        continue;
      }
      if (i == left.index) {
        textSpans.addAll(span.buildSelectingSpan(left.offset, span.textLength));
      }
      if (i == right.index) {
        textSpans.addAll(span.buildSelectingSpan(0, right.offset));
      }
    }
    return TextSpan(children: textSpans);
  }

  TextSpan buildTextSpanWithCursor(BasicCursor c, int index) {
    if (c is SelectingNodeCursor && c.index == index) {
      final begin = c.begin;
      final end = c.end;
      if (begin is RichTextNodePosition && end is RichTextNodePosition) {
        return selectingTextSpan(begin, end);
      }
    } else if (c is SelectingNodesCursor && c.contains(index)) {
      final left = c.left;
      final right = c.right;

      if (left.index < index && right.index > index) {
        return selectingTextSpan(beginPosition, endPosition);
      } else if (left.index == index) {
        final position = left.position;
        if (position is RichTextNodePosition) {
          return selectingTextSpan(position, endPosition);
        }
      } else if (right.index == index) {
        final position = right.position;
        if (position is RichTextNodePosition) {
          return selectingTextSpan(beginPosition, position);
        }
      }
    }
    return textSpan;
  }

  @override
  RichTextNode frontPartNode(RichTextNodePosition end, {String? newId}) =>
      getFromPosition(beginPosition, end, newId: newId);

  @override
  RichTextNode rearPartNode(RichTextNodePosition begin, {String? newId}) =>
      getFromPosition(begin, endPosition, newId: newId);

  @override
  RichTextNode merge(EditorNode other, {String? newId}) {
    if (other is! RichTextNode) {
      throw UnableToMergeException(runtimeType, other.runtimeType);
    }
    final copySpans = List.of(spans);
    int offset = copySpans.last.endOffset;
    for (var span in other.spans) {
      copySpans.add(span.copy(offset: to(offset)));
      offset += copySpans.last.textLength;
    }
    return RichTextNode._(UnmodifiableListView(copySpans), id: newId ?? id);
  }

  RichTextNode onDelete(RichTextNodePosition position) {
    if (position == beginPosition) {
      throw DeleteRequiresNewLineException(runtimeType);
    }
    if (position.offset == 0) {
      final lastSpan = spans[position.index - 1];
      return remove(
          RichTextNodePosition(position.index - 1, lastSpan.offset - 1),
          position);
    }
    return remove(
        RichTextNodePosition(position.index, position.offset - 1), position);
  }

  @override
  Map<String, dynamic> toJson() =>
      {'nodes': spans.map((e) => e.toJson()).toList()};

  String get text => spans.map((e) => e.text).join(',');

  @override
  RichTextNodePosition get beginPosition => RichTextNodePosition.zero();

  @override
  RichTextNodePosition get endPosition =>
      RichTextNodePosition(spans.length - 1, spans.last.textLength);

  @override
  Widget build(EditorContext context, int index) =>
      RichTextWidget(context, this, index);

  RichTextNode insert(int index, RichTextSpan span) {
    final copySpans = List.of(spans);
    copySpans.insert(index, span);
    int offset = index == 0 ? 0 : copySpans[index - 1].endOffset;
    for (var i = index; i < copySpans.length; ++i) {
      var n = copySpans[i];
      copySpans[i] = n.copy(offset: to(offset));
      offset += n.textLength;
    }
    return RichTextNode._(UnmodifiableListView(copySpans), id: id);
  }

  RichTextNode update(int index, RichTextSpan span) {
    final copySpans = List.of(spans);
    copySpans[index] = span;
    int offset = index == 0 ? 0 : copySpans[index - 1].endOffset;
    for (var i = index; i < copySpans.length; ++i) {
      var n = copySpans[i];
      copySpans[i] = n.copy(offset: to(offset));
      offset += n.textLength;
    }
    return RichTextNode._(UnmodifiableListView(copySpans), id: id);
  }

  RichTextNode remove(RichTextNodePosition begin, RichTextNodePosition end) {
    return replace(begin, end, []);
  }

  RichTextNode replace(RichTextNodePosition begin, RichTextNodePosition end,
      List<RichTextSpan> spans,
      {String? newId}) {
    RichTextNodePosition left = begin.lowerThan(end) ? begin : end;
    RichTextNodePosition right = begin.lowerThan(end) ? end : begin;

    final copySpans = List.of(this.spans);
    final leftIndex = left.index;
    final rightIndex = right.index;
    int offset = copySpans[leftIndex].offset;
    var leftNode = copySpans[leftIndex];
    var rightNode = copySpans[right.index];
    if (leftIndex == rightIndex) {
      copySpans.removeAt(leftIndex);
    } else {
      copySpans.removeRange(leftIndex, rightIndex + 1);
    }
    leftNode = leftNode.copy(text: (t) => t.substring(0, left.offset));
    rightNode =
        rightNode.copy(text: (t) => t.substring(right.offset, t.length));
    if (rightNode.text.isNotEmpty) copySpans.insert(leftIndex, rightNode);
    copySpans.insertAll(leftIndex, spans);
    if (leftNode.text.isNotEmpty) copySpans.insert(leftIndex, leftNode);
    int i = leftIndex;
    while (i < copySpans.length) {
      copySpans[i] = copySpans[i].copy(offset: to(offset));
      offset += copySpans[i].textLength;
      i++;
    }
    return RichTextNode._(UnmodifiableListView(copySpans), id: newId ?? id);
  }

  int locateSpanIndex(int offset) {
    if (spans.length <= 1 || offset <= 0) return 0;
    if (offset >= spans.last.offset) return spans.length - 1;
    int left = 0;
    int right = spans.length - 1;
    while (left < right) {
      final mid = (right + left) ~/ 2;
      final midSpan = spans[mid];
      if (midSpan.inRange(offset)) return mid;
      if (midSpan.endOffset < offset) {
        left = mid + 1;
      } else if (midSpan.offset > offset) {
        right = mid;
      } else {
        return mid;
      }
    }
    return left;
  }

  RichTextSpan getSpan(int index) => spans[index];

  @override
  RichTextNode getFromPosition(
      RichTextNodePosition begin, RichTextNodePosition end,
      {String? newId}) {
    if (begin == end) {
      return RichTextNode.empty(id: newId ?? id);
    }
    RichTextNodePosition left = begin.lowerThan(end) ? begin : end;
    RichTextNodePosition right = begin.lowerThan(end) ? end : begin;
    if (left.sameIndex(right)) {
      final span = spans[left.index].copy(
          offset: to(0), text: (v) => v.substring(left.offset, right.offset));
      return RichTextNode._(UnmodifiableListView([span]), id: newId ?? id);
    } else {
      final beginIndex = left.index;
      final endIndex = right.index;
      final newSpans = <RichTextSpan>[];
      for (var i = beginIndex; i < endIndex + 1; ++i) {
        var span = spans[i];
        if (i == beginIndex) {
          span = span.copy(
              offset: to(0), text: (v) => v.substring(left.offset, v.length));
        } else if (i == endIndex) {
          final text = span.text.substring(0, right.offset);
          span = span.copy(offset: to(newSpans.last.endOffset), text: to(text));
        } else {
          span = span.copy(offset: to(newSpans.last.endOffset));
        }
        newSpans.add(span);
      }
      return RichTextNode._(UnmodifiableListView(newSpans), id: newId ?? id);
    }
  }
}

abstract class SpanNode {
  InlineSpan buildSpan();
}
