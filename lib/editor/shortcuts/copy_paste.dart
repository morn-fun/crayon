import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pre_editor/editor/node/rich_text_node/rich_text_span.dart';

import '../command/modification.dart';
import '../command/replacement.dart';
import '../command/selecting_nodes/paste.dart';
import '../core/context.dart';
import '../core/controller.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import '../node/basic_node.dart';
import '../node/position_data.dart';
import '../node/rich_text_node/rich_text_node.dart';

class CopyIntent extends Intent {
  const CopyIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}

class CopyAction extends ContextAction<CopyIntent> {
  final EditorContext editorContext;

  CopyAction(this.editorContext);

  @override
  void invoke(CopyIntent intent, [BuildContext? context]) async {
    logger.i('$runtimeType is invoking!');
    final cursor = editorContext.cursor;
    if (cursor is EditingCursor) return;
    final controller = editorContext.controller;
    if (cursor is SelectingNodeCursor) {
      final node = controller.getNode(cursor.index);
      final newNode =
          node.getFromPosition(cursor.begin, cursor.end, newId: randomNodeId);
      _copiedNodes.clear();
      _copiedNodes.add(newNode);
    } else if (cursor is SelectingNodesCursor) {
      final List<EditorNode> nodes = [];
      final left = cursor.left, right = cursor.right;
      var beginNode = controller.getNode(left.index);
      var endNode = controller.getNode(right.index);
      beginNode = beginNode.rearPartNode(left.position, newId: randomNodeId);
      endNode = endNode.frontPartNode(right.position, newId: randomNodeId);
      nodes.add(beginNode);
      nodes.addAll(controller.getRange(left.index + 1, right.index));
      nodes.add(endNode);
      _copiedNodes.clear();
      _copiedNodes.addAll(nodes);
    }
    String text = _copiedNodes.map((e) => e.text).join('\n');
    Clipboard.setData(ClipboardData(text: '$_specialEdge$text$_specialEdge'));
  }
}

final List<EditorNode> _copiedNodes = [];

const _specialEdge = '\u{200C}';

class PasteAction extends ContextAction<PasteIntent> {
  final EditorContext editorContext;

  PasteAction(this.editorContext);

  @override
  void invoke(PasteIntent intent, [BuildContext? context]) async {
    logger.i('$runtimeType is invoking!');
    final data = await Clipboard.getData('text/plain');
    if (data is! ClipboardData) return;
    final text = data.text ?? '';
    if (text.isEmpty) return;
    final List<EditorNode> nodes = [];
    if (text.startsWith(_specialEdge) && text.endsWith(_specialEdge)) {
      for (var n in _copiedNodes) {
        nodes.add(n.newIdNode());
      }
    } else {
      nodes.add(RichTextNode.from([RichTextSpan(text: text)]));
    }
    final cursor = editorContext.cursor;
    final controller = editorContext.controller;
    if (cursor is EditingCursor) {
      final index = cursor.index;
      final node = controller.getNode(index);
      try {
        final r = node.onEdit(
            EditingData(cursor.position, EventType.paste, extras: nodes));
        editorContext.execute(ModifyNode(r.position.toCursor(index), r.node));
      } on UnablePasteExcepting catch (e) {
        editorContext.execute(ReplaceNode(Replace(index, index + 1, e.nodes,
            EditingCursor(index + e.nodes.length - 1, e.position))));
      }
    } else if (cursor is SelectingNodeCursor) {
      final index = cursor.index;
      final node = controller.getNode(index);
      try {
        final r = node.onSelect(SelectingData(
            SelectingPosition(cursor.left, cursor.right), EventType.paste,
            extras: nodes));
        editorContext.execute(ModifyNode(r.position.toCursor(index), r.node));
      } on UnablePasteExcepting catch (e) {
        editorContext.execute(ReplaceNode(Replace(index, index + 1, e.nodes,
            EditingCursor(index + e.nodes.length - 1, e.position))));
      }
    } else if (cursor is SelectingNodesCursor) {
      editorContext.execute(PasteWhileSelectingNodes(cursor, nodes));
    }
  }
}
