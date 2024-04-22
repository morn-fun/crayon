import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart' hide RichText;
import '../../core/node_controller.dart';
import '../../exception/string_exception.dart';
import '../../extension/string_extension.dart';
import '../../extension/collection_extension.dart';
import '../../core/copier.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../widget/nodes/rich_text.dart';
import '../basic_node.dart';
import '../position_data.dart';
import 'generator/depth.dart';
import 'generator/paste.dart';
import 'generator/styles.dart';
import 'generator/deletion.dart';
import 'generator/select_all.dart';
import 'generator/typing.dart';
import 'rich_text_span.dart';

class RichTextNode extends EditorNode {
  ///there must be at least one span in [spans]
  final UnmodifiableListView<RichTextSpan> spans;

  RichTextNode.from(List<RichTextSpan> spans, {super.id, super.depth})
      : spans = _buildInitSpans(spans);

  RichTextNode from(List<RichTextSpan> spans, {String? id, int? depth}) =>
      RichTextNode.from(spans, id: id ?? this.id, depth: depth ?? this.depth);

  static UnmodifiableListView<RichTextSpan> _buildInitSpans(
      List<RichTextSpan> spans) {
    if (spans.isEmpty) return UnmodifiableListView([RichTextSpan()]);
    return UnmodifiableListView(spans);
  }

  TextSpan buildTextSpan({TextStyle? style}) {
    return TextSpan(
        children:
            List.generate(spans.length, (index) => spans[index].buildSpan()),
        style: style);
  }

  TextSpan buildTextSpanWithCursor(BasicCursor cursor, int index,
      {TextStyle? style}) {
    if (cursor is SelectingNodeCursor && cursor.index == index) {
      final left = cursor.left;
      final right = cursor.right;
      if (left is RichTextNodePosition && right is RichTextNodePosition) {
        return selectingTextSpan(left, right, style: style);
      }
    } else if (cursor is SelectingNodesCursor && cursor.contains(index)) {
      final left = cursor.left;
      final right = cursor.right;
      if (left.index < index && right.index > index) {
        return selectingTextSpan(beginPosition, endPosition, style: style);
      } else if (left.index == index) {
        final position = left.position;
        if (position is RichTextNodePosition) {
          return selectingTextSpan(position, endPosition, style: style);
        }
      } else if (right.index == index) {
        final position = right.position;
        if (position is RichTextNodePosition) {
          return selectingTextSpan(beginPosition, position, style: style);
        }
      }
    }
    return buildTextSpan(style: style);
  }

  TextSpan selectingTextSpan(
      RichTextNodePosition begin, RichTextNodePosition end,
      {TextStyle? style}) {
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
    return TextSpan(children: textSpans, style: style);
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
    return from(UnmodifiableListView(RichTextSpan.mergeList(copySpans)),
        id: newId ?? id);
  }

  @override
  Map<String, dynamic> toJson() =>
      {'type': runtimeType, 'nodes': spans.map((e) => e.toJson()).toList()};

  @override
  String get text => spans.map((e) => e.text).join('');

  @override
  RichTextNodePosition get beginPosition => RichTextNodePosition.zero();

  @override
  RichTextNodePosition get endPosition =>
      RichTextNodePosition(spans.length - 1, spans.last.textLength);

  @override
  Widget build(NodeController controller, SingleNodePosition? position,
          dynamic extras) =>
      RichText(controller, this, position);

  RichTextNode insert(int index, RichTextSpan span) {
    final copySpans = List.of(spans);
    copySpans.insert(index, span);
    return from(UnmodifiableListView(RichTextSpan.mergeList(copySpans)),
        id: id);
  }

  RichTextNode insertByPosition(
      RichTextNodePosition position, RichTextSpan span) {
    final index = position.index;
    final currentSpan = spans[index];
    final copySpans = List.of(spans);
    copySpans.replaceRange(
        index, index + 1, currentSpan.insert(position.offset, span));
    return from(UnmodifiableListView(RichTextSpan.mergeList(copySpans)),
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
    return from(UnmodifiableListView(RichTextSpan.mergeList(copySpans)),
        id: id);
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
    return from(UnmodifiableListView(RichTextSpan.mergeList(copySpans)),
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
    return min(left, right);
  }

  RichTextNodePosition getPositionByOffset(int offset) {
    int index = locateSpanIndex(offset);
    final span = spans[index];
    return RichTextNodePosition(index, offset - span.offset);
  }

  RichTextSpan getSpan(int index) => spans[index];

  List<RichTextSpan> buildSpansByAddingTag(String tag,
          {Map<String, String>? attributes}) =>
      spans
          .map((e) => e.copy(
                tags: (tags) => tags.addOne(tag),
                attributes: (a) => attributes ?? a,
              ))
          .toList();

  List<RichTextSpan> buildSpansByRemovingTag(String tag,
          {Map<String, String>? attributes}) =>
      spans
          .map((e) => e.copy(
                tags: (tags) => tags.removeOne(tag),
                attributes: (a) => attributes ?? a,
              ))
          .toList();

  @override
  RichTextNode getFromPosition(
      covariant RichTextNodePosition begin, covariant RichTextNodePosition end,
      {String? newId}) {
    if (begin == beginPosition && end == endPosition) {
      return from(spans, id: newId ?? id, depth: depth);
    }
    if (begin == end) {
      return from([], id: newId ?? id, depth: depth);
    }
    RichTextNodePosition left = begin.isLowerThan(end) ? begin : end;
    RichTextNodePosition right = begin.isLowerThan(end) ? end : begin;
    if (left.sameIndex(right)) {
      final span = spans[left.index].copy(
          offset: to(0), text: (v) => v.substring(left.offset, right.offset));
      return from(UnmodifiableListView([span]), id: newId ?? id, depth: depth);
    } else {
      final leftIndex = left.index;
      final rightIndex = right.index;
      var leftSpan = spans[leftIndex];
      var rightSpan = spans[rightIndex];
      leftSpan = leftSpan.copy(text: (t) => t.substring(left.offset, t.length));
      rightSpan = rightSpan.copy(text: (t) => t.substring(0, right.offset));
      final newSpans = List.of(spans.getRange(leftIndex, rightIndex + 1));
      newSpans.removeAt(0);
      newSpans.removeLast();
      newSpans.insert(0, leftSpan);
      newSpans.add(rightSpan);
      return from(UnmodifiableListView(RichTextSpan.mergeList(newSpans)),
          id: newId ?? id, depth: depth);
    }
  }

  NodeWithPosition delete(covariant RichTextNodePosition position) {
    if (position == beginPosition) {
      throw DeleteRequiresNewLineException(position);
    }
    final index = position.index;
    final lastIndex = index - 1;
    if (position.offset == 0) {
      final lastSpan = spans[lastIndex];
      final newSpan = lastSpan.copy(text: (t) => t.removeLast());
      final newOffset = newSpan.text.length;
      final newPosition = RichTextNodePosition(lastIndex, newOffset);
      return NodeWithPosition(
          update(lastIndex, newSpan), EditingPosition(newPosition));
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
            EditingPosition(
                RichTextNodePosition(lastIndex, lastSpan.textLength)));
      }
      return NodeWithPosition(
          update(position.index, newSpan), EditingPosition(newPosition));
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
        throw ArrowLeftBeginException(position);
      } on OffsetIsEndException {
        throw ArrowLeftBeginException(position);
      }
    } else {
      final span = spans[index];
      try {
        final newOffset = span.text.lastOffset(offset);
        return RichTextNodePosition(index, newOffset);
      } on RangeError {
        throw ArrowLeftBeginException(position);
      }
    }
  }

  RichTextNodePosition nextPositionByLength(
      RichTextNodePosition position, int l) {
    int targetOffset = getOffset(position) + l;
    final targetPosition = getPositionByOffset(targetOffset);
    return nextPosition(targetPosition);
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
        throw ArrowRightEndException(position);
      } on OffsetIsEndException {
        throw ArrowRightEndException(position);
      }
    } else {
      try {
        final newOffset = span.text.nextOffset(position.offset);
        return RichTextNodePosition(index, newOffset);
      } on RangeError {
        throw ArrowRightEndException(position);
      }
    }
  }

  int getOffset(RichTextNodePosition position) =>
      spans[position.index].offset + position.offset;

  @override
  NodeWithPosition onEdit(EditingData data) {
    final generator = _editingGenerator[data.type.name];
    if (generator == null) {
      return NodeWithPosition(this, EditingPosition(data.position));
    }
    return generator.call(data.as<RichTextNodePosition>(), this);
  }

  @override
  NodeWithPosition onSelect(SelectingData data) {
    final generator = _selectingGenerator[data.type.name];
    if (generator == null) {
      return NodeWithPosition(this, data.position);
    }
    return generator.call(data.as<RichTextNodePosition>(), this);
  }

  @override
  EditorNode newNode({String? id, int? depth}) =>
      from(spans, id: id ?? this.id, depth: depth ?? this.depth);

  bool get isEmpty {
    if (spans.isEmpty) return true;
    bool result = true;
    for (var s in spans) {
      if (s.text.isNotEmpty) return false;
    }
    return result;
  }

  @override
  List<EditorNode> getInlineNodesFromPosition(
          covariant RichTextNodePosition begin,
          covariant RichTextNodePosition end) =>
      [getFromPosition(begin, end)];
}

final _editingGenerator = <String, _NodeGeneratorWhileEditing>{
  EventType.delete.name: (d, n) => n.delete(d.position),
  EventType.newline.name: (d, n) => throw NewlineRequiresNewNode(n.runtimeType),
  EventType.selectAll.name: (d, n) => selectAllRichTextNodeWhileEditing(d, n),
  EventType.typing.name: (d, n) => typingRichTextNodeWhileEditing(d, n),
  EventType.paste.name: (d, n) => pasteWhileEditing(d, n),
  EventType.increaseDepth.name: (d, n) => increaseDepthWhileEditing(d, n),
  EventType.decreaseDepth.name: (d, n) =>
      throw DepthNeedDecreaseMoreException(n.runtimeType, n.depth),
  ...Map.fromEntries(RichTextTag.values.map((e) =>
      MapEntry(e.name, (d, n) => styleRichTextNodeWhileEditing(d, n, e.name)))),
};

final _selectingGenerator = <String, _NodeGeneratorWhileSelecting>{
  EventType.delete.name: (d, n) => deleteRichTextNodeWhileSelecting(d, n),
  EventType.newline.name: (d, n) => throw NewlineRequiresNewNode(n.runtimeType),
  EventType.selectAll.name: (d, n) => selectAllRichTextNodeWhileSelecting(d, n),
  EventType.typing.name: (d, n) => typingRichTextNodeWhileSelecting(d, n),
  EventType.paste.name: (d, n) => pasteWhileSelecting(d, n),
  EventType.increaseDepth.name: (d, n) => increaseDepthWhileSelecting(d, n),
  EventType.decreaseDepth.name: (d, n) =>
      throw DepthNeedDecreaseMoreException(n.runtimeType, n.depth),
  ...Map.fromEntries(RichTextTag.values.map((e) => MapEntry(
      e.name, (d, n) => styleRichTextNodeWhileSelecting(d, n, e.name)))),
};

typedef _NodeGeneratorWhileEditing = NodeWithPosition Function(
    EditingData<RichTextNodePosition> data, RichTextNode node);

typedef _NodeGeneratorWhileSelecting = NodeWithPosition Function(
    SelectingData<RichTextNodePosition> data, RichTextNode node);

abstract class SpanNode {
  InlineSpan buildSpan();
}
