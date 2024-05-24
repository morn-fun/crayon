import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crayon/editor/node/rich_text/ordered.dart';

import '../../config/const_texts.dart';
import '../../config/necessary.dart';

void main() {
  test('test pre text RegExp', () {
    RegExp orderedRegExp = RegExp(r'^(\+)?\d+(\.)$');
    const s1 = '1.2.3.4.';
    final match1 = orderedRegExp.allMatches(s1);
    assert(match1.isEmpty);

    const s2 = '1.';
    final match2 = orderedRegExp.allMatches(s2);
    assert(match2.length == 1);

    const s3 = '11.';
    final match3 = orderedRegExp.allMatches(s3);
    assert(match3.length == 1);

    const s4 = '-11.';
    final match4 = orderedRegExp.allMatches(s4);
    assert(match4.isEmpty);

    const s5 = '11';
    final match5 = orderedRegExp.allMatches(s5);
    assert(match5.isEmpty);

    const s6 = '11..';
    final match6 = orderedRegExp.allMatches(s6);
    assert(match6.isEmpty);

    const s7 = '.11.';
    final match7 = orderedRegExp.allMatches(s7);
    assert(match7.isEmpty);
  });

  test('generateOrderedNumber', () {
    assert(generateOrderedNumber(1, 0) == '1');
    assert(generateOrderedNumber(10, 0) == '10');
    assert(generateOrderedNumber(100, 0) == '100');
    assert(generateOrderedNumber(1, 3) == '1');
    assert(generateOrderedNumber(10, 3) == '10');
    assert(generateOrderedNumber(100, 3) == '100');

    assert(generateOrderedNumber(1, 1) == 'I');
    assert(generateOrderedNumber(2, 1) == 'II');
    assert(generateOrderedNumber(3, 1) == 'III');
    assert(generateOrderedNumber(4, 1) == 'IV');
    assert(generateOrderedNumber(5, 1) == 'V');
    assert(generateOrderedNumber(6, 1) == 'VI');
    assert(generateOrderedNumber(7, 1) == 'VII');
    assert(generateOrderedNumber(8, 1) == 'VIII');
    assert(generateOrderedNumber(9, 1) == 'IX');
    assert(generateOrderedNumber(10, 1) == 'X');
    assert(generateOrderedNumber(11, 1) == 'XI');
    assert(generateOrderedNumber(49, 1) == 'XLIX');
    assert(generateOrderedNumber(50, 1) == 'L');
    assert(generateOrderedNumber(51, 1) == 'LI');
    assert(generateOrderedNumber(99, 1) == 'XCIX');
    assert(generateOrderedNumber(100, 1) == 'C');
    assert(generateOrderedNumber(101, 1) == 'CI');
    assert(generateOrderedNumber(499, 1) == 'CDXCIX');
    assert(generateOrderedNumber(500, 1) == 'D');
    assert(generateOrderedNumber(501, 1) == 'DI');
    assert(generateOrderedNumber(999, 1) == 'CMXCIX');
    assert(generateOrderedNumber(1000, 1) == 'M');
    assert(generateOrderedNumber(1001, 1) == 'MI');
    assert(generateOrderedNumber(1999, 1) == 'MCMXCIX');
    assert(generateOrderedNumber(5999, 1) == 'MMMMMCMXCIX');
    assert(generateOrderedNumber(1, 4) == 'I');
    assert(generateOrderedNumber(5999, 4) == 'MMMMMCMXCIX');

    assert(generateOrderedNumber(1, 2) == 'a');
    assert(generateOrderedNumber(2, 2) == 'b');
    assert(generateOrderedNumber(3, 2) == 'c');
    assert(generateOrderedNumber(25, 2) == 'y');
    assert(generateOrderedNumber(26, 2) == 'z');
    assert(generateOrderedNumber(27, 2) == 'aa');
    assert(generateOrderedNumber(52, 2) == 'az');
    assert(generateOrderedNumber(78, 2) == 'bz');
    assert(generateOrderedNumber(1, 5) == 'a');
    assert(generateOrderedNumber(78, 5) == 'bz');

    expect(() => generateOrderedNumber(-1, 1),
        throwsA(const TypeMatcher<Exception>()));
    expect(() => generateOrderedNumber(-1, 2),
        throwsA(const TypeMatcher<Exception>()));
  });

  test('from', () {
    OrderedNode node =
        OrderedNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    assert(node.spans.length == constTexts.length);
    for (var i = 0; i < node.spans.length; ++i) {
      final span = node.spans[i];
      final text = constTexts[i];
      assert(span.text == text);
    }

    final newNode = node.from([]);
    assert(newNode.isEmpty);
    assert(newNode.spans.length == 1);
  });

  test('toJson', () {
    OrderedNode node =
        OrderedNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    final json = node.toJson();
    assert(json['type'] == 'OrderedNode');
  });

  testWidgets('build', (tester) async {
    var node =
        OrderedNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    final ctx = buildEditorContext([
      node,
      ...List.generate(
          10, (index) => node.newNode(id: randomNodeId, depth: index)),
      ...List.generate(10, (index) => node.newNode(id: randomNodeId, depth: 0)),
    ]);

    for (var i = 0; i < ctx.nodeLength; ++i) {
      var node = ctx.nodes[i];
      var widget =
          Builder(builder: (c) => node.build(ctx, NodeBuildParam(index: i), c));
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ));
    }
  });
}
