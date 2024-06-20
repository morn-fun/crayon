import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/divider.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/divider/divider.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../config/necessary.dart';

void main() {
  test('getFromPosition', () {
    final node = DividerNode();
    final begin = node.beginPosition;
    final end = node.endPosition;
    assert(node.getFromPosition(begin, begin).id == node.id);
    assert(node.getFromPosition(end, end).id == node.id);
    assert(node.getFromPosition(begin, end).id == node.id);
    assert(node.getFromPosition(begin, end, newId: 'xxx').id == 'xxx');
    assert(node.getFromPosition(begin, end, newId: 'xxx').id != node.id);
  });

  test('getInlineNodesFromPosition', () {
    final node = DividerNode();
    assert(node
        .getInlineNodesFromPosition(node.beginPosition, node.endPosition)
        .isEmpty);
  });

  test('merge', () {
    final node = DividerNode();
    final n1 = DividerNode();
    expect(() => node.merge(n1),
        throwsA(const TypeMatcher<UnableToMergeException>()));
  });

  test('newNode', () {
    final node = DividerNode();
    final n1 = node.newNode(id: 'xxx');
    final n2 = node.newNode(depth: 2);
    assert(node.id == n2.id);
    assert(node.depth == n1.depth);
    assert(n1.id == 'xxx');
    assert(n2.depth == 2);
  });

  test('onEdit-onSelect-delete', () {
    final node = DividerNode();
    final ctx = buildEditorContext([node]);
    try {
      node.onEdit(EditingData(
          EditingCursor(0, DividerPosition()), EventType.delete, ctx));
    } on NewlineRequiresNewSpecialNode catch (e) {
      assert(e.newNodes.length == 2);
      assert(e.newNodes.first is RichTextNode);
      assert(e.newNodes.last is RichTextNode);
      assert(e.newNodes.first.text.isEmpty);
      assert(e.newNodes.last.text.isEmpty);
    }

    try {
      node.onSelect(SelectingData(
          SelectingNodeCursor(0, DividerPosition(), DividerPosition()),
          EventType.delete,
          ctx));
    } on NewlineRequiresNewSpecialNode catch (e) {
      assert(e.newNodes.length == 2);
      assert(e.newNodes.first is RichTextNode);
      assert(e.newNodes.last is RichTextNode);
      assert(e.newNodes.first.text.isEmpty);
      assert(e.newNodes.last.text.isEmpty);
    }
  });

  test('onEdit-onSelect-newline', () {
    final node = DividerNode();
    final ctx = buildEditorContext([node]);
    try {
      node.onEdit(EditingData(
          EditingCursor(0, DividerPosition()), EventType.newline, ctx));
    } on NewlineRequiresNewSpecialNode catch (e) {
      assert(e.newNodes.length == 2);
      assert(e.newNodes.first is RichTextNode);
      assert(e.newNodes.last is RichTextNode);
      assert(e.newNodes.first.text.isEmpty);
      assert(e.newNodes.last.text.isEmpty);
    }

    try {
      node.onSelect(SelectingData(
          SelectingNodeCursor(0, DividerPosition(), DividerPosition()),
          EventType.newline,
          ctx));
    } on NewlineRequiresNewSpecialNode catch (e) {
      assert(e.newNodes.length == 2);
      assert(e.newNodes.first is RichTextNode);
      assert(e.newNodes.last is RichTextNode);
      assert(e.newNodes.first.text.isEmpty);
      assert(e.newNodes.last.text.isEmpty);
    }
  });

  test('onEdit-onSelect-selectAll', () {
    final node = DividerNode();
    final ctx = buildEditorContext([node]);
    try {
      node.onEdit(EditingData(
          EditingCursor(0, DividerPosition()), EventType.selectAll, ctx));
    } on EmptyNodeToSelectAllException catch (e) {
      assert(e.id == node.id);
    }

    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(0, DividerPosition(), DividerPosition()),
            EventType.selectAll,
            ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
  });

  test('onEdit-onSelect-paste', () {
    final node = DividerNode();
    final ctx = buildEditorContext([node]);

    expect(
        () => node.onEdit(EditingData(
            EditingCursor(0, DividerPosition()), EventType.paste, ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(0, DividerPosition(), DividerPosition()),
            EventType.paste,
            ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));

    try {
      node.onEdit(EditingData(
          EditingCursor(0, DividerPosition()), EventType.delete, ctx,
          extras: [DividerNode()]));
    } on PasteToCreateMoreNodesException catch (e) {
      assert(e.nodes.length == 1);
      assert(e.nodes.first is DividerNode);
    }

    try {
      node.onSelect(SelectingData(
          SelectingNodeCursor(0, DividerPosition(), DividerPosition()),
          EventType.paste,
          ctx,
          extras: [DividerNode(), DividerNode()]));
    } on PasteToCreateMoreNodesException catch (e) {
      assert(e.nodes.length == 2);
      assert(e.nodes.first is DividerNode);
      assert(e.nodes.last is DividerNode);
    }
  });

  test('onEdit-onSelect-increaseDepth', () {
    final node = DividerNode();
    final ctx = buildEditorContext([node]);

    expect(
        () => node.onEdit(EditingData(
            EditingCursor(0, DividerPosition()), EventType.increaseDepth, ctx,
            extras: -1)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(0, DividerPosition(), DividerPosition()),
            EventType.increaseDepth,
            ctx,
            extras: -1)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));

    final r1 = node.onEdit(EditingData(
        EditingCursor(0, DividerPosition()), EventType.increaseDepth, ctx));
    assert(r1.node.depth == 1);
    assert(r1.node.id == node.id);

    final r2 = node.onSelect(SelectingData(
        SelectingNodeCursor(0, DividerPosition(), DividerPosition()),
        EventType.increaseDepth,
        ctx,
        extras: 10));
    assert(r2.node.depth == 1);
    assert(r2.node.id == node.id);
  });

  test('onEdit-onSelect-decreaseDepth', () {
    final node = DividerNode();
    final ctx = buildEditorContext([node]);

    expect(
        () => node.onEdit(EditingData(
            EditingCursor(0, DividerPosition()), EventType.decreaseDepth, ctx)),
        throwsA(const TypeMatcher<DepthNeedDecreaseMoreException>()));
    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(0, DividerPosition(), DividerPosition()),
            EventType.decreaseDepth,
            ctx)),
        throwsA(const TypeMatcher<DepthNeedDecreaseMoreException>()));
  });

  test('onEdit-onSelect-bold', () {
    final node = DividerNode();
    final ctx = buildEditorContext([node]);

    expect(
        () => node.onEdit(EditingData(
            EditingCursor(0, DividerPosition()), EventType.bold, ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
    expect(
        () => node.onSelect(SelectingData(
            SelectingNodeCursor(0, DividerPosition(), DividerPosition()),
            EventType.bold,
            ctx)),
        throwsA(const TypeMatcher<NodeUnsupportedException>()));
  });

  test('text', () {
    final node = DividerNode();
    assert(node.text == '---');
  });

  test('toJson', () {
    final node = DividerNode();
    final json = node.toJson();
    assert(json['type'] == node.runtimeType.toString());
  });

  testWidgets('build', (tester) async {
    final node = DividerNode();
    final ctx = buildEditorContext([node]);
    var widget =
        Builder(builder: (c) => node.build(ctx, NodeBuildParam.empty(), c));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ));
  });
}
