import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../command/modification.dart';
import '../command/replacement.dart';
import '../command/selecting/paste.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import '../core/logger.dart';
import '../cursor/basic.dart';
import '../exception/editor_node.dart';
import '../node/basic.dart';
import '../node/rich_text/head.dart';
import '../node/rich_text/ordered.dart';
import '../node/rich_text/rich_text.dart';
import '../node/rich_text/rich_text_span.dart';
import '../node/rich_text/unordered.dart';

class CopyIntent extends Intent {
  const CopyIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}

class CopyAction extends ContextAction<CopyIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  BasicCursor get cursor => operator.cursor;

  CopyAction(this.ac);

  @override
  void invoke(CopyIntent intent, [BuildContext? context]) async {
    logger.i('$runtimeType is invoking!');
    final cursor = this.cursor;
    if (cursor is EditingCursor) return;
    if (cursor is SelectingNodeCursor) {
      final node = operator.getNode(cursor.index);
      final newNode =
          node.getFromPosition(cursor.begin, cursor.end, newId: randomNodeId);
      _copiedNodes.clear();
      _copiedNodes.add(newNode);
    } else if (cursor is SelectingNodesCursor) {
      final List<EditorNode> nodes = [];
      final left = cursor.left, right = cursor.right;
      var beginNode = operator.getNode(left.index);
      var endNode = operator.getNode(right.index);
      beginNode = beginNode.rearPartNode(left.position, newId: randomNodeId);
      endNode = endNode.frontPartNode(right.position, newId: randomNodeId);
      nodes.add(beginNode);
      nodes.addAll(operator.getRange(left.index + 1, right.index));
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
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  BasicCursor get cursor => operator.cursor;

  PasteAction(this.ac);

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
        nodes.add(n.newNode(id: randomNodeId));
      }
    } else {
      _copiedNodes.clear();
      final stringList = text.split(RegExp(r'\r\n|\r|\n'));
      final keys = _string2generator.keys.toList();
      for (var s in stringList) {
        if (s.startsWith(orderedRegExp)) {
          nodes.add(OrderedNode.from(
              [RichTextSpan(text: s.replaceFirst(orderedRegExp, ''))]));
        } else {
          int i = 0;
          bool isSpecialNode = false;
          while (i < keys.length) {
            final frontText = keys[i];
            if (s.startsWith(frontText)) {
              nodes.add(_string2generator[frontText]!
                  .call(s.replaceFirst(frontText, '')));
              isSpecialNode = true;
              i = keys.length;
            }
            i++;
          }
          if (!isSpecialNode) {
            nodes.add(RichTextNode.from([RichTextSpan(text: s)]));
          }
        }
      }
    }
    final cursor = this.cursor;
    if (cursor is EditingCursor) {
      final index = cursor.index;
      final node = operator.getNode(index);
      try {
        final r = node.onEdit(
            EditingData(cursor, EventType.paste, operator, extras: nodes));
        operator.execute(ModifyNode(r));
      } on PasteToCreateMoreNodesException catch (e) {
        operator.execute(ReplaceNode(Replace(index, index + 1, e.nodes,
            EditingCursor(index + e.nodes.length - 1, e.position))));
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    } else if (cursor is SelectingNodeCursor) {
      final index = cursor.index;
      final node = operator.getNode(index);
      try {
        final r = node.onSelect(
            SelectingData(cursor, EventType.paste, operator, extras: nodes));
        operator.execute(ModifyNode(r));
      } on PasteToCreateMoreNodesException catch (e) {
        operator.execute(ReplaceNode(Replace(index, index + 1, e.nodes,
            EditingCursor(index + e.nodes.length - 1, e.position))));
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    } else if (cursor is SelectingNodesCursor) {
      operator.execute(PasteWhileSelectingNodes(cursor, nodes));
    }
  }
}

RegExp orderedRegExp = RegExp(r'^(\+)?\d+(\.)$');

typedef _NodeGenerator = EditorNode Function(String v);

final Map<String, _NodeGenerator> _string2generator = {
  '-': (n) => UnorderedNode.from([RichTextSpan(text: n)]),
  '#': (n) => H1Node.from([RichTextSpan(text: n)]),
  '##': (n) => H2Node.from([RichTextSpan(text: n)]),
  '###': (n) => H3Node.from([RichTextSpan(text: n)]),
};
