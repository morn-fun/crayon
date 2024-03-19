import 'dart:collection';

import 'package:flutter/material.dart';

import '../../core/copier.dart';
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

  bool inRange(int off) => off >= offset && off <= endOffset;

  int get textLength => text.length;

  int get endOffset => offset + textLength;

  @override
  InlineSpan buildSpan() => TextSpan(text: text, style: _buildStyle());

  List<InlineSpan> buildSelectingSpan(int begin, int end) {
    assert(begin <= end);
    return [
      if (begin != 0)
        TextSpan(text: text.substring(0, begin), style: _buildStyle()),
      TextSpan(
          text: text.substring(begin, end),
          style: _buildStyle().copyWith(backgroundColor: Colors.blue)),
      if (end != textLength)
        TextSpan(text: text.substring(end, textLength), style: _buildStyle()),
    ];
  }

  TextStyle _buildStyle() {
    var style = const TextStyle();
    for (final tag in tags) {
      style = style.merge(_tag2Style[tag]);
    }
    return style;
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

Map<String, TextStyle> _tag2Style = {
  RichTextTag.del.name: const TextStyle(decoration: TextDecoration.lineThrough),
  RichTextTag.strong.name: const TextStyle(fontWeight: FontWeight.bold),
  RichTextTag.em.name: const TextStyle(fontStyle: FontStyle.italic),
  RichTextTag.a.name: const TextStyle(color: Color(0xff0969da)),
};

enum RichTextTag { a, del, strong, em }
