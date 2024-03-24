import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../command/basic_command.dart';
import '../../command/rich_text_node/bold.dart';
import '../../command/rich_text_node/deletion.dart';
import '../../command/rich_text_node/newline.dart';
import '../../command/rich_text_node/select_all.dart';
import '../../command/rich_text_node/typing.dart';
import '../../core/events.dart';
import '../../core/logger.dart';
import '../../exception/string_exception.dart';
import '../../extension/string_extension.dart';
import '../../extension/collection_extension.dart';
import '../../core/context.dart';
import '../../core/copier.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../shortcuts/arrows/arrows.dart';
import '../../widget/rich_text_widget.dart';
import '../basic_node.dart';
import 'rich_text_span.dart';

class RichTextNode extends EditorNode {
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

  TextSpan buildTextSpanWithCursor(BasicCursor c, int index) {
    if (c is SelectingNodeCursor && c.index == index) {
      final left = c.left;
      final right = c.right;
      if (left is RichTextNodePosition && right is RichTextNodePosition) {
        return selectingTextSpan(left, right);
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

  TextSpan selectingTextSpan(
      RichTextNodePosition begin, RichTextNodePosition end) {
    RichTextNodePosition left = begin.isLowerThan(end) ? begin : end;
    RichTextNodePosition right = begin.isLowerThan(end) ? end : begin;
    final textSpans = <InlineSpan>[];
    for (var i = 0; i < spans.length; ++i) {
      var span = spans[i];
      if (i < left.index || i > right.index) {
        textSpans.add(span.buildSpan());
        continue;
      }
      if (left.index == right.index && left.index == i) {
        textSpans.addAll(span.buildSelectingSpan(left.offset, right.offset));
        continue;
      }
      if (i == left.index) {
        textSpans.addAll(span.buildSelectingSpan(left.offset, span.textLength));
        continue;
      } else if (i == right.index) {
        textSpans.addAll(span.buildSelectingSpan(0, right.offset));
        continue;
      }
      if (i > left.index || i < right.index) {
        textSpans.addAll(span.buildSelectingSpan(0, span.textLength));
      }
    }
    return TextSpan(children: textSpans);
  }

  @override
  RichTextNode frontPartNode(covariant RichTextNodePosition end,
          {String? newId}) =>
      getFromPosition(beginPosition, end, newId: newId);

  @override
  RichTextNode rearPartNode(covariant RichTextNodePosition begin,
          {String? newId}) =>
      getFromPosition(begin, endPosition, newId: newId);

  @override
  RichTextNode merge(EditorNode other, {String? newId}) {
    if (other is! RichTextNode) {
      throw UnableToMergeException(
          runtimeType.toString(), other.runtimeType.toString());
    }
    final copySpans = List.of(spans);
    copySpans.addAll(other.spans);
    return RichTextNode._(
        UnmodifiableListView(RichTextSpan.mergeList(copySpans)),
        id: newId ?? id);
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

  RichTextNode insert(int index, RichTextSpan span, {bool trim = false}) {
    final copySpans = List.of(spans);
    copySpans.insert(index, span);
    return RichTextNode._(
        UnmodifiableListView(RichTextSpan.mergeList(copySpans, trim: trim)),
        id: id);
  }

  RichTextNode insertByPosition(
      RichTextNodePosition position, RichTextSpan span,
      {bool trim = false}) {
    final index = position.index;
    final currentSpan = spans[index];
    final copySpans = List.of(spans);
    copySpans.replaceRange(index, index + 1,
        currentSpan.insert(position.offset, span, trim: trim));
    return RichTextNode._(
        UnmodifiableListView(RichTextSpan.mergeList(copySpans, trim: trim)),
        id: id);
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
    RichTextNodePosition left = begin.isLowerThan(end) ? begin : end;
    RichTextNodePosition right = begin.isLowerThan(end) ? end : begin;

    final copySpans = List.of(this.spans);
    final leftIndex = left.index;
    final rightIndex = right.index;
    var leftSpan = copySpans[leftIndex];
    var rightSpan = copySpans[rightIndex];
    if (leftIndex == rightIndex) {
      copySpans.removeAt(leftIndex);
    } else {
      copySpans.removeRange(leftIndex, rightIndex + 1);
    }
    leftSpan = leftSpan.copy(text: (t) => t.substring(0, left.offset));
    rightSpan =
        rightSpan.copy(text: (t) => t.substring(right.offset, t.length));
    final newSpans = List.of(spans);
    if (rightSpan.text.isNotEmpty) newSpans.add(rightSpan);
    if (leftSpan.text.isNotEmpty) newSpans.insert(0, leftSpan);
    copySpans.insertAll(leftIndex, newSpans);
    return RichTextNode._(
        UnmodifiableListView(RichTextSpan.mergeList(copySpans)),
        id: newId ?? id);
  }

  int locateSpanIndex(int offset) {
    if (spans.length <= 1 || offset <= 0) return 0;
    if (offset >= spans.last.endOffset) return spans.length - 1;
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

  RichTextNodePosition getPositionByOffset(int offset, {bool trim = true}) {
    int index = locateSpanIndex(offset);
    final span = spans[index];
    if (trim) {
      if (span.isEmpty && index - 1 >= 0) {
        return RichTextNodePosition(index - 1, spans[index - 1].textLength);
      }
    }
    return RichTextNodePosition(index, offset - span.offset);
  }

  RichTextSpan getSpan(int index) => spans[index];

  List<RichTextSpan> buildSpansByAddingTag(String tag) =>
      spans.map((e) => e.copy(tags: (tags) => tags.addOne(tag))).toList();

  List<RichTextSpan> buildSpansByRemovingTag(String tag) =>
      spans.map((e) => e.copy(tags: (tags) => tags.removeOne(tag))).toList();

  @override
  RichTextNode getFromPosition(
      covariant RichTextNodePosition begin, covariant RichTextNodePosition end,
      {String? newId, bool trim = false}) {
    if (begin == end) {
      return RichTextNode.empty(id: newId ?? id);
    }
    RichTextNodePosition left = begin.isLowerThan(end) ? begin : end;
    RichTextNodePosition right = begin.isLowerThan(end) ? end : begin;
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
        if (!trim || !span.isEmpty) newSpans.add(span);
      }
      return RichTextNode._(UnmodifiableListView(newSpans), id: newId ?? id);
    }
  }

  @override
  NodeWithPosition? delete(covariant RichTextNodePosition position) {
    if (position == beginPosition) {
      throw DeleteRequiresNewLineException(runtimeType);
    }
    final index = position.index;
    final lastIndex = index - 1;
    if (position.offset == 0) {
      final lastSpan = spans[lastIndex];
      final newSpan = lastSpan.copy(text: (t) => t.removeLast());
      final newOffset = newSpan.text.length;
      final newPosition = RichTextNodePosition(lastIndex, newOffset);
      return NodeWithPosition(update(lastIndex, newSpan), newPosition);
    } else {
      final span = spans[index];
      final text = span.text;
      final stringWithOffset = text.removeAt(position.offset);
      final newSpan = span.copy(text: to(stringWithOffset.text));
      final newOffset = stringWithOffset.offset;
      final newPosition = RichTextNodePosition(index, newOffset);
      if (newSpan.isEmpty && index > 0) {
        final lastSpan = spans[lastIndex];
        return NodeWithPosition(
            replace(RichTextNodePosition(lastIndex, 0),
                RichTextNodePosition(index, span.textLength), [lastSpan]),
            RichTextNodePosition(lastIndex, lastSpan.textLength));
      }
      return NodeWithPosition(update(position.index, newSpan), newPosition);
    }
  }

  RichTextNodePosition lastPosition(RichTextNodePosition position) {
    final index = position.index;
    final lastIndex = index - 1;
    final offset = position.offset;
    if (offset == 0) {
      try {
        final lastSpan = spans[lastIndex];
        final newOffset = lastSpan.text.lastOffset(lastSpan.textLength);
        return RichTextNodePosition(lastIndex, newOffset);
      } on RangeError {
        throw ArrowIsEndException(ArrowType.left, position);
      } on OffsetIsEndException {
        throw ArrowIsEndException(ArrowType.left, position);
      }
    } else {
      final span = spans[index];
      try {
        final newOffset = span.text.lastOffset(offset);
        return RichTextNodePosition(index, newOffset);
      } on OffsetIsEndException {
        throw ArrowIsEndException(ArrowType.left, position);
      }
    }
  }

  RichTextNodePosition nextPositionByLength(
      RichTextNodePosition position, int l) {
    int index = position.index;
    int offset = position.offset;
    int restLength = l + offset;
    while (index < spans.length && restLength > 0) {
      final span = spans[index];
      if (restLength < span.textLength) {
        return RichTextNodePosition(index, offset);
      }
      restLength = restLength - span.textLength;
      offset = span.offset;
      index++;
    }
    return RichTextNodePosition(index, offset);
  }

  RichTextNodePosition nextPosition(RichTextNodePosition position) {
    final index = position.index;
    final nextIndex = index + 1;
    final offset = position.offset;
    final span = spans[index];
    if (offset == span.textLength) {
      try {
        final nextSpan = spans[nextIndex];
        final newOffset = nextSpan.text.nextOffset(0);
        return RichTextNodePosition(nextIndex, newOffset);
      } on RangeError {
        throw ArrowIsEndException(ArrowType.right, position);
      } on OffsetIsEndException {
        throw ArrowIsEndException(ArrowType.right, position);
      }
    } else {
      try {
        final newOffset = span.text.nextOffset(position.offset);
        return RichTextNodePosition(index, newOffset);
      } on OffsetIsEndException {
        throw ArrowIsEndException(ArrowType.right, position);
      }
    }
  }

  int getOffset(RichTextNodePosition position) =>
      spans[position.index].offset + position.offset;

  @override
  BasicCommand? handleEventWhileEditing(EditingEvent event) {
    logger.i('handleEventWhileEditing event 【$event】');
    final cursor = event.cursor;
    final generator = _editingType2Command[event.type];
    if (generator == null) return null;
    return generator.call(
        cursor.as<RichTextNodePosition>(), this, event.extras);
  }

  @override
  BasicCommand? handleEventWhileSelecting(SelectingNodeEvent event) {
    logger.i('handleEventWhileSelecting event 【$event】');
    final cursor = event.cursor;
    final generator = _selectingType2Command[event.type];
    if (generator == null) return null;
    return generator.call(
        cursor.as<RichTextNodePosition>(), this, event.extras);
  }
}

final _editingType2Command = <EventType, _EditingCommandGenerator>{
  EventType.delete: (c, n, e) => DeleteWhileEditingRichTextNode(c, n),
  EventType.newline: (c, n, e) => InsertNewlineWhileEditingRichTextNode(c, n),
  EventType.selectAll: (c, n, e) => SelectAllWhileEditingRichTextNode(c, n),
  EventType.typing: (c, n, e) =>
      generateRichTextCommandWhileEditing(c, n, e as TextEditingDelta),
  EventType.bold: (c, n, e) => BoldWhileEditingRichTextNode(c, n),
};

final _selectingType2Command = <EventType, _SelectingCommandGenerator>{
  EventType.delete: (c, n, e) => DeleteWhileSelectingRichTextNode(c, n),
  EventType.newline: (c, n, e) => InsertNewlineWhileSelectingRichTextNode(c, n),
  EventType.selectAll: (c, n, e) => SelectAllWhileSelectingRichTextNode(c, n),
  EventType.typing: (c, n, e) =>
      generateRichTextCommandWhileSelecting(c, n, e as TextEditingDelta),
  EventType.bold: (c, n, e) => BoldWhileSelectingRichTextNode(c, n),
};

typedef _EditingCommandGenerator = BasicCommand? Function(
    EditingCursor<RichTextNodePosition> cursor,
    RichTextNode node,
    dynamic extra);

typedef _SelectingCommandGenerator = BasicCommand? Function(
    SelectingNodeCursor<RichTextNodePosition> cursor,
    RichTextNode node,
    dynamic extra);

abstract class SpanNode {
  InlineSpan buildSpan();
}
