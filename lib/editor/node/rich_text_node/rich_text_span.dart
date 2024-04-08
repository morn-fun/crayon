import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:pre_editor/editor/extension/collection_extension.dart';

import '../../core/copier.dart';
import '../../exception/editor_node_exception.dart';
import 'rich_text_node.dart';

class RichTextSpan extends SpanNode {
  final UnmodifiableMapView<String, String> attributes;
  final String text;
  final UnmodifiableSetView<String> tags;
  final int offset;

  RichTextSpan({
    this.text = '',
    Map<String, String> attributes = const {},
    Set<String> tags = const {},
    this.offset = 0,
  })  : attributes = UnmodifiableMapView(attributes),
        tags = UnmodifiableSetView(tags);

  RichTextSpan copy({
    ValueCopier<String>? text,
    ValueCopier<Map<String, String>>? attributes,
    ValueCopier<Set<String>>? tags,
    ValueCopier<int>? offset,
  }) {
    return RichTextSpan(
      text: text?.call(this.text) ?? this.text,
      attributes: attributes?.call(this.attributes) ?? this.attributes,
      tags: tags?.call(this.tags) ?? this.tags,
      offset: offset?.call(this.offset) ?? this.offset,
    );
  }

  bool inRange(int off) => off >= offset && off < endOffset;

  int get textLength => text.length;

  int get endOffset => offset + textLength;

  @override
  InlineSpan buildSpan() => TextSpan(text: text, style: buildStyle());

  List<InlineSpan> buildSelectingSpan(int begin, int end) {
    assert(begin <= end);
    return [
      if (begin != 0)
        TextSpan(text: text.substring(0, begin), style: buildStyle()),
      TextSpan(
          text: text.substring(begin, end),
          style: buildStyle().copyWith(backgroundColor: Colors.blue)),
      if (end != textLength)
        TextSpan(text: text.substring(end, textLength), style: buildStyle()),
    ];
  }

  RichTextSpan merge(RichTextSpan other, {bool trim = true}) {
    if (trim && other.isEmpty) return this;
    if (trim && isEmpty) return other;
    if (!tags.equalsTo(other.tags) || !attributes.equalsTo(other.attributes)) {
      throw UnableToMergeException(toString(), other.toString());
    }
    return copy(text: (t) => t + other.text);
  }

  static List<RichTextSpan> mergeList(List<RichTextSpan> list,
      {bool trim = true}) {
    if (list.length < 2) return List.of(list);
    List<RichTextSpan> result = [];
    var lastSpan = list.first;
    int offset = lastSpan.offset;
    for (var i = 1; i < list.length; ++i) {
      final span = list[i];
      try {
        lastSpan = lastSpan.merge(span, trim: trim);
        if (i == list.length - 1) result.add(lastSpan);
      } on UnableToMergeException {
        result.add(lastSpan.copy(offset: to(offset)));
        offset += lastSpan.textLength;
        lastSpan = span.copy(offset: to(offset));
        if (i == list.length - 1) result.add(lastSpan);
      }
    }
    return result;
  }

  List<RichTextSpan> insert(int offset, RichTextSpan span, {bool trim = true}) {
    List<RichTextSpan> list = [];
    if (text.substring(0, offset).isNotEmpty) {
      list.add(copy(text: (t) => t.substring(0, offset)));
    }
    list.add(span);
    if (text.substring(offset, textLength).isNotEmpty) {
      list.add(copy(text: (t) => t.substring(offset, t.length)));
    }
    return mergeList(list, trim: trim);
  }

  TextStyle buildStyle() {
    var style = const TextStyle();
    Set<TextDecoration> decorations = {};
    for (final tag in tags) {
      final s = tag2Style[tag];
      final decoration = s?.decoration;
      if (decoration != null) {
        decorations.add(decoration);
      }
      style = style.merge(s);
    }
    return style.copyWith(
        decoration: TextDecoration.combine(decorations.toList()),
        color: Colors.black);
  }

  Map<String, dynamic> toJson() => {
        'attributes': attributes,
        'text': text,
        if (tags.isNotEmpty) 'tags': tags.toSet(),
      };

  bool get isEmpty => text.isEmpty;

  @override
  String toString() {
    return 'RichTextSpan{attributes: $attributes, text: $text, tags: $tags, offset: $offset}';
  }
}

Map<String, TextStyle> tag2Style = {
  RichTextTag.lineThrough.name:
      const TextStyle(decoration: TextDecoration.lineThrough),
  RichTextTag.bold.name: const TextStyle(fontWeight: FontWeight.bold),
  RichTextTag.italic.name: const TextStyle(fontStyle: FontStyle.italic),
  RichTextTag.underline.name:
      const TextStyle(decoration: TextDecoration.underline),
  RichTextTag.link.name: const TextStyle(color: Color(0xff0969da)),
};

enum RichTextTag { link, underline, bold, italic, lineThrough }
