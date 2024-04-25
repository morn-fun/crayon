import 'package:crayon/editor/cursor/rich_text_cursor.dart';
import 'package:crayon/editor/exception/editor_node_exception.dart';
import 'package:crayon/editor/node/basic_node.dart';
import 'package:crayon/editor/node/position_data.dart';
import 'package:crayon/editor/node/rich_text_node/ordered_node.dart';
import 'package:crayon/editor/node/rich_text_node/ordered_unordered_mixin.dart';
import 'package:crayon/editor/node/rich_text_node/rich_text_span.dart';
import 'package:crayon/editor/node/rich_text_node/unordered_node.dart';
import 'package:flutter_test/flutter_test.dart';

import 'config/const_texts.dart';

void main() {
  test('onEdit', () {
    OrderedUnorderedMixin node =
        OrderedNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    expect(
        () => node
            .onEdit(EditingData(RichTextNodePosition.zero(), EventType.delete)),
        throwsA(const TypeMatcher<DeleteToChangeNodeException>()));

    expect(
        () => node.onEdit(
            EditingData(RichTextNodePosition.zero(), EventType.newline)),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    expect(
        () => node.from([]).onEdit(
            EditingData(RichTextNodePosition.zero(), EventType.newline)),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    var np = node.from([]).onEdit(
        EditingData(RichTextNodePosition.zero(), EventType.increaseDepth));
    assert(np.node.depth - node.depth == 1);

    node = UnorderedNode.from(
        constTexts.map((e) => RichTextSpan(text: e)).toList());

    expect(
        () => node
            .onEdit(EditingData(RichTextNodePosition.zero(), EventType.delete)),
        throwsA(const TypeMatcher<DeleteToChangeNodeException>()));

    expect(
        () => node.onEdit(
            EditingData(RichTextNodePosition.zero(), EventType.newline)),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    expect(
        () => node.from([]).onEdit(
            EditingData(RichTextNodePosition.zero(), EventType.newline)),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    np = node.from([]).onEdit(
        EditingData(RichTextNodePosition.zero(), EventType.increaseDepth));
    assert(np.node.depth - node.depth == 1);
  });

  test('onSelect', () {
    OrderedUnorderedMixin node =
        OrderedNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());

    expect(
        () => node.onSelect(SelectingData(
            SelectingPosition(
                RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
            EventType.newline)),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    var np = node.from([]).onSelect(SelectingData(
        SelectingPosition(
            RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
        EventType.increaseDepth));
    assert(np.node.depth > node.depth);

    node = UnorderedNode.from(
        constTexts.map((e) => RichTextSpan(text: e)).toList());

    expect(
        () => node.onSelect(SelectingData(
            SelectingPosition(
                RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
            EventType.newline)),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    np = node.from([]).onSelect(SelectingData(
        SelectingPosition(
            RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
        EventType.increaseDepth));
    assert(np.node.depth > node.depth);
  });
}
