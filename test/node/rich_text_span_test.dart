import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pre_editor/editor/exception/editor_node_exception.dart';
import 'package:pre_editor/editor/extension/collection_extension.dart';
import 'package:pre_editor/editor/node/rich_text_node/rich_text_node.dart';
import 'package:pre_editor/editor/node/rich_text_node/rich_text_span.dart';

void main() {
  test('copyTest', () {
    final span = RichTextSpan(
        text: '001', attributes: {'1': '1'}, tags: {'x'}, offset: 0);
    final span2 = span.copy(text: (t) => '0$t');
    final span3 =
        span.copy(tags: (tags) => tags.removeOne('x'), offset: (off) => 1);
    assert(span2.text == '0001');
    assert(span.attributes.equalsTo(span2.attributes));
    assert(span.tags.equalsTo(span2.tags));
    assert(!span.tags.equalsTo(span3.tags));
    assert(span3.offset == 1);
  });

  test('inRange', () {
    final span = RichTextSpan(text: '123456', offset: 0);
    assert(!span.inRange(-1));
    assert(!span.inRange(span.textLength));
    for (var i = 0; i < span.textLength; ++i) {
      assert(span.inRange(i));
    }
  });

  test('buildSelectingSpan', () {
    final context = SpanNodeContext();
    final span = RichTextSpan(
        text: '123456', offset: 0, tags: {RichTextTag.lineThrough.name});
    final spans1 = span.buildSelectingSpan(0, 1, context);
    assert(spans1.length == 2);
    final spans2 = span.buildSelectingSpan(3, 6, context);
    assert(spans2.length == 2);
    final spans3 = span.buildSelectingSpan(2, 4, context);
    assert(spans3.length == 3);
  });

  test('merge', () {
    final span =
        RichTextSpan(text: '123', offset: 0, tags: {RichTextTag.italic.name});
    final span2 = RichTextSpan(text: '456', offset: 0);
    final span3 =
        RichTextSpan(text: '789', offset: 0, tags: {RichTextTag.italic.name});
    final span4 = RichTextSpan();
    expect(() => span.merge(span2),
        throwsA(const TypeMatcher<UnableToMergeException>()));
    expect(() => span3.merge(span4, trim: false),
        throwsA(const TypeMatcher<UnableToMergeException>()));
    assert(span3.merge(span4) == span3);
    assert(span.merge(span3).textLength == span.textLength + span3.textLength);
  });

  test('mergeList', () {
    final span =
        RichTextSpan(text: '123', offset: 0, tags: {RichTextTag.italic.name});
    final span2 = RichTextSpan(text: '456', offset: 0);
    final span3 =
        RichTextSpan(text: '789', offset: 0, tags: {RichTextTag.italic.name});

    var list = RichTextSpan.mergeList([span, span2, span3]);
    assert(list.length == 3);
    assert(list[0].textLength == span.textLength);
    assert(list[0].offset == 0);
    assert(list[1].textLength == span2.textLength);
    assert(list[1].offset == list[0].endOffset);
    assert(list[2].textLength == span3.textLength);
    assert(list[2].offset == list[1].endOffset);

    final span4 = RichTextSpan(text: '', offset: 0);
    final span5 =
        RichTextSpan(text: '', offset: 0, tags: {RichTextTag.italic.name});
    final span6 =
        RichTextSpan(text: 'xxx', offset: 0, tags: {RichTextTag.bold.name});
    list = RichTextSpan.mergeList([span, span2, span3, span4], trim: false);
    int offset = 0;
    for (var o in list) {
      assert(o.offset == offset);
      offset += o.textLength;
    }
    assert(list.length == 4);
    list = RichTextSpan.mergeList([span, span2, span3, span4]);
    offset = 0;
    for (var o in list) {
      assert(o.offset == offset);
      offset += o.textLength;
    }
    assert(list.length == 3);
    list = RichTextSpan.mergeList([span, span2, span3, span4, span5]);
    assert(list.length == 3);
    offset = 0;
    for (var o in list) {
      assert(o.offset == offset);
      offset += o.textLength;
    }

    list = RichTextSpan.mergeList([span, span3, span5], trim: false);
    assert(list.length == 1);
    offset = 0;
    for (var o in list) {
      assert(o.offset == offset);
      offset += o.textLength;
    }

    list = RichTextSpan.mergeList([span, span3, span5, span6], trim: false);
    assert(list.length == 2);
    offset = 0;
    for (var o in list) {
      assert(o.offset == offset);
      offset += o.textLength;
    }
  });

  test('insert', () {
    final tag = RichTextTag.italic.name;
    final span = RichTextSpan(text: '123456', offset: 0, tags: {tag});
    var list = span.insert(3, RichTextSpan());
    assert(list.length == 1);
    assert(list.first.textLength == span.textLength);

    list = span.insert(3, RichTextSpan());
    assert(list.length == 1);

    list = span.insert(3, RichTextSpan(), trim: false);
    assert(list.length == 3);
    assert(list[0].text == '123');
    assert(list[0].tags.equalsTo({tag}));

    assert(list[1].text == '');
    assert(list[1].tags.isEmpty);

    assert(list[2].text == '456');
    assert(list[2].tags.equalsTo({tag}));

    assert(span.insert(3, RichTextSpan(tags: {'a'}), trim: false).length == 3);
    assert(span.insert(3, RichTextSpan(tags: {'a'})).length == 1);
  });

  test('other', () {
    final span = RichTextSpan(text: '123456', offset: 0, tags: {'x'});
    final textSpan = span.buildSpan(SpanNodeContext()) as TextSpan;
    assert(textSpan.text == span.text);
    final json = span.toJson();
    assert((json['tags'] as Set).equalsTo(span.tags));
    assert((json['attributes'] as Map).isEmpty);
    assert(json['text'] == span.text);
  });
}
