import 'package:crayon/editor/core/listener_collection.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/cursor/node_position.dart';
import 'package:crayon/editor/node/rich_text/ordered.dart';
import 'package:crayon/editor/node/rich_text/special_newline_mixin.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/node/rich_text/unordered.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/const_texts.dart';

void main() {
  test('onEdit', () {
    SpecialNewlineMixin node =
        OrderedNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());
    expect(
        () => node.onEdit(EditingData(RichTextNodePosition.zero(),
            EventType.delete, ListenerCollection())),
        throwsA(const TypeMatcher<DeleteToChangeNodeException>()));

    expect(
        () => node.onEdit(EditingData(RichTextNodePosition.zero(),
            EventType.newline, ListenerCollection())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    expect(
        () => node.from([]).onEdit(EditingData(RichTextNodePosition.zero(),
            EventType.newline, ListenerCollection())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    var np = node.from([]).onEdit(EditingData(RichTextNodePosition.zero(),
        EventType.increaseDepth, ListenerCollection()));
    assert(np.node.depth - node.depth == 1);

    node = UnorderedNode.from(
        constTexts.map((e) => RichTextSpan(text: e)).toList());

    expect(
        () => node.onEdit(EditingData(RichTextNodePosition.zero(),
            EventType.delete, ListenerCollection())),
        throwsA(const TypeMatcher<DeleteToChangeNodeException>()));

    expect(
        () => node.onEdit(EditingData(RichTextNodePosition.zero(),
            EventType.newline, ListenerCollection())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    expect(
        () => node.from([]).onEdit(EditingData(RichTextNodePosition.zero(),
            EventType.newline, ListenerCollection())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    np = node.from([]).onEdit(EditingData(RichTextNodePosition.zero(),
        EventType.increaseDepth, ListenerCollection()));
    assert(np.node.depth - node.depth == 1);
  });

  test('onSelect', () {
    SpecialNewlineMixin node =
        OrderedNode.from(constTexts.map((e) => RichTextSpan(text: e)).toList());

    expect(
        () => node.onSelect(SelectingData(
            SelectingPosition(
                RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
            EventType.newline,
            ListenerCollection())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    var np = node.from([]).onSelect(SelectingData(
        SelectingPosition(
            RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
        EventType.increaseDepth,
        ListenerCollection()));
    assert(np.node.depth > node.depth);

    node = UnorderedNode.from(
        constTexts.map((e) => RichTextSpan(text: e)).toList());

    expect(
        () => node.onSelect(SelectingData(
            SelectingPosition(
                RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
            EventType.newline,
            ListenerCollection())),
        throwsA(const TypeMatcher<NewlineRequiresNewSpecialNode>()));

    np = node.from([]).onSelect(SelectingData(
        SelectingPosition(
            RichTextNodePosition.zero(), RichTextNodePosition(5, 0)),
        EventType.increaseDepth,
        ListenerCollection()));
    assert(np.node.depth > node.depth);
  });
}
