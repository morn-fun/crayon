import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/rich_text/ordered.dart';
import 'package:crayon/editor/node/rich_text/special_newline_mixin.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/node/rich_text/unordered.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../config/const_texts.dart';
import '../../config/test_node_context.dart';


void main() {
  test('onEdit', () {
    SpecialNewlineMixin node =
        OrderedNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    final emptyCursor = EditingCursor(0, RichTextNodePosition.zero());
    expect(
        () => node.onEdit(
            EditingData(emptyCursor, EventType.delete, TestNodeContext())),
        throwsA(const TypeMatcher<DeleteToChangeNodeException>()));

    expect(
        () => node.onEdit(
            EditingData(emptyCursor, EventType.newline, TestNodeContext())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    expect(
        () => node.from([]).onEdit(
            EditingData(emptyCursor, EventType.newline, TestNodeContext())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    var np = node.from([]).onEdit(
        EditingData(emptyCursor, EventType.increaseDepth, TestNodeContext()));
    assert(np.node.depth - node.depth == 1);

    node = UnorderedNode.from(
        constTexts.map((e) => RichTextSpan(text: e)).toList());

    expect(
        () => node.onEdit(
            EditingData(emptyCursor, EventType.delete, TestNodeContext())),
        throwsA(const TypeMatcher<DeleteToChangeNodeException>()));

    expect(
        () => node.onEdit(
            EditingData(emptyCursor, EventType.newline, TestNodeContext())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    expect(
        () => node.from([]).onEdit(
            EditingData(emptyCursor, EventType.newline, TestNodeContext())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    np = node.from([]).onEdit(
        EditingData(emptyCursor, EventType.increaseDepth, TestNodeContext()));
    assert(np.node.depth - node.depth == 1);
  });

  test('onSelect', () {
    SpecialNewlineMixin node =
        OrderedNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());

    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(
                0, RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
            EventType.newline,
            TestNodeContext())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    var np = node.from([]).onSelect(SelectingData(
        SelectingNodeCursor(
            0, RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
        EventType.increaseDepth,
        TestNodeContext()));
    assert(np.node.depth > node.depth);

    node = UnorderedNode.from(
        constTexts.map((e) => RichTextSpan(text: e)).toList());

    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(
                0, RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
            EventType.newline,
            TestNodeContext())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    np = node.from([]).onSelect(SelectingData(
        SelectingNodeCursor(
            0, RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
        EventType.increaseDepth,
        TestNodeContext()));
    assert(np.node.depth > node.depth);
  });
}
