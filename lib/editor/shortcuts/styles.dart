import 'package:flutter/material.dart';

import '../command/modification.dart';
import '../command/selecting/update.dart';
import '../core/context.dart';
import '../core/logger.dart';
import '../cursor/basic.dart';
import '../cursor/rich_text.dart';
import '../exception/editor_node.dart';
import '../node/basic.dart';
import '../node/rich_text/rich_text.dart';
import '../node/rich_text/rich_text_span.dart';

class UnderlineIntent extends Intent {
  const UnderlineIntent();
}

class BoldIntent extends Intent {
  const BoldIntent();
}

class ItalicIntent extends Intent {
  const ItalicIntent();
}

class LineThroughIntent extends Intent {
  const LineThroughIntent();
}

class UnderlineAction extends ContextAction<UnderlineIntent> {
  final ActionContext ac;

  NodesOperator get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  UnderlineAction(this.ac);

  @override
  void invoke(UnderlineIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    onStyleEvent(nodeContext, RichTextTag.underline, cursor);
  }
}

class BoldAction extends ContextAction<BoldIntent> {
  final ActionContext ac;

  NodesOperator get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  BoldAction(this.ac);

  @override
  void invoke(BoldIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    onStyleEvent(nodeContext, RichTextTag.bold, cursor);
  }
}

class ItalicAction extends ContextAction<ItalicIntent> {
  final ActionContext ac;

  NodesOperator get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  ItalicAction(this.ac);

  @override
  void invoke(ItalicIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    onStyleEvent(nodeContext, RichTextTag.italic, cursor);
  }
}

class LineThroughAction extends ContextAction<LineThroughIntent> {
  final ActionContext ac;

  NodesOperator get nodeContext => ac.context;

  BasicCursor get cursor => ac.cursor;

  LineThroughAction(this.ac);

  @override
  void invoke(LineThroughIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    onStyleEvent(nodeContext, RichTextTag.lineThrough, cursor);
  }
}

void onStyleEvent(NodesOperator context, RichTextTag tag, BasicCursor cursor,
    {Map<String, String>? attributes}) {
  try {
    final type = EventType.values.byName(tag.name);
    if (cursor is SingleNodeCursor) {
      if (cursor is EditingCursor) {
        final r = context.getNode(cursor.index).onEdit(EditingData(
            cursor, type, context,
            extras: StyleExtra(false, attributes)));
        context.execute(ModifyNode(r));
      } else if (cursor is SelectingNodeCursor) {
        final node = context.getNode(cursor.index);
        final innerNodes =
            node.getInlineNodesFromPosition(cursor.begin, cursor.end);
        bool containsTag = true;
        int i = 0;
        while (i < innerNodes.length && containsTag) {
          final innerNode = innerNodes[i];
          if (innerNode is RichTextNode) {
            for (var s in innerNode.spans) {
              if (!s.tags.contains(type.name)) {
                containsTag = false;
                break;
              }
            }
          }
          i++;
        }
        final r = context.getNode(cursor.index).onSelect(SelectingData(
            cursor, type, context,
            extras: StyleExtra(containsTag, attributes)));
        context.execute(ModifyNode(r));
      }
    } else if (cursor is SelectingNodesCursor) {
      final left = cursor.left;
      final right = cursor.right;
      int i = left.index;
      bool containsTag = true;
      while (i <= right.index && containsTag) {
        final node = context.getNode(i);
        if (node is RichTextNode) {
          late RichTextNode newNode;
          if (i == left.index) {
            newNode = node.rearPartNode(left.position as RichTextNodePosition);
          } else if (i == right.index) {
            newNode =
                node.frontPartNode(right.position as RichTextNodePosition);
          } else {
            newNode = node;
          }
          for (var s in newNode.spans) {
            if (!s.tags.contains(type.name)) {
              containsTag = false;
              break;
            }
          }
        }
        i++;
      }
      context.execute(UpdateSelectingNodes(cursor, type,
          extra: StyleExtra(containsTag, attributes)));
    }
  } on ArgumentError catch (e) {
    logger.e('onStyleEvent error: $e');
  } on NodeUnsupportedException catch (e) {
    logger.e('$tag, ${e.message}');
  }
}

class StyleExtra {
  final bool containsTag;
  final Map<String, String>? attributes;

  StyleExtra(this.containsTag, this.attributes);
}
