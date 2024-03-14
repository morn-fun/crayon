import 'dart:collection';

import 'package:flutter/material.dart';
import '../../core/context.dart';
import '../../core/copier.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../widget/rich_text_widget.dart';
import '../basic_node.dart';
import 'rich_text_span.dart';

class RichTextNode extends EditorNode<RichTextNodePosition> {
  final UnmodifiableListView<RichTextSpan> spans;

  RichTextNode._(this.spans, {super.id});

  RichTextNode.empty() : spans = UnmodifiableListView([]);

  RichTextNode.from(List<RichTextSpan> spans)
      : spans = UnmodifiableListView(spans);

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
      if(left.index == right.index) {
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
    if (other.spans.isEmpty) {
      return RichTextNode._(spans, id: newId ?? id);
    }
    if (spans.isEmpty) {
      return RichTextNode._(other.spans, id: newId ?? other.id);
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

  @override
  RichTextNodePosition get beginPosition => RichTextNodePosition.zero();

  @override
  RichTextNodePosition get endPosition => spans.isEmpty
      ? RichTextNodePosition.zero()
      : RichTextNodePosition(spans.length - 1, spans.last.textLength);

  @override
  Widget build(EditorContext context, int index) =>
      RichTextWidget(context, this, index, key: ValueKey(id));

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
    if (this.spans.isEmpty && spans.isEmpty) {
      return RichTextNode._(this.spans, id: newId ?? id);
    }
    if (this.spans.isEmpty) {
      final copySpans = <RichTextSpan>[];
      int offset = 0;
      for (var span in spans) {
        copySpans.add(span.copy(offset: to(offset)));
        offset += copySpans.last.textLength;
      }
      return RichTextNode._(UnmodifiableListView(copySpans), id: newId ?? id);
    }

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
    assert(begin != end);
    RichTextNodePosition left = begin.lowerThan(end) ? begin : end;
    RichTextNodePosition right = begin.lowerThan(end) ? end : begin;
    if (left.sameIndex(right)) {
      final span = spans[left.index].copy(
          offset: to(0), text: (v) => v.substring(left.offset, right.offset));
      return RichTextNode._(UnmodifiableListView([span]), id: id);
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
