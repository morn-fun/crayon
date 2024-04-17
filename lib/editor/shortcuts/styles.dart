import 'package:flutter/material.dart';
import 'package:pre_editor/editor/cursor/rich_text_cursor.dart';

import '../command/selecting_nodes/update.dart';
import '../core/context.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import '../node/rich_text_node/rich_text_node.dart';
import '../node/rich_text_node/rich_text_span.dart';

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
  final EditorContext editorContext;

  UnderlineAction(this.editorContext);

  @override
  void invoke(UnderlineIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    onStyleEvent(editorContext, RichTextTag.underline);
  }
}

class BoldAction extends ContextAction<BoldIntent> {
  final EditorContext editorContext;

  BoldAction(this.editorContext);

  @override
  void invoke(BoldIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    onStyleEvent(editorContext, RichTextTag.bold);
  }
}

class ItalicAction extends ContextAction<ItalicIntent> {
  final EditorContext editorContext;

  ItalicAction(this.editorContext);

  @override
  void invoke(ItalicIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    onStyleEvent(editorContext, RichTextTag.italic);
  }
}

class LineThroughAction extends ContextAction<LineThroughIntent> {
  final EditorContext editorContext;

  LineThroughAction(this.editorContext);

  @override
  void invoke(LineThroughIntent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    onStyleEvent(editorContext, RichTextTag.lineThrough);
  }
}

void onStyleEvent(EditorContext context, RichTextTag tag,
    {Map<String, String>? attributes}) {
  final cursor = context.cursor;
  final controller = context.controller;
  try {
    final type = EventType.values.byName(tag.name);
    if (cursor is SingleNodeCursor) {
      context.onNodeEditing(cursor, type, extra: StyleExtra(false, attributes));
    } else if (cursor is SelectingNodesCursor) {
      final left = cursor.left;
      final right = cursor.right;
      int i = left.index;
      bool coverTag = false;
      while (i <= right.index) {
        final node = controller.getNode(i);
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
              coverTag = true;
              i = right.index + 1;
              break;
            }
          }
        }
        i++;
      }
      context.execute(UpdateSelectingNodes(cursor, type,
          extra: StyleExtra(coverTag, attributes)));
    }
  } on ArgumentError catch (e) {
    logger.e('onStyleEvent error: $e');
  }
}

class StyleExtra {
  final bool containsTag;
  final Map<String, String>? attributes;

  StyleExtra(this.containsTag, this.attributes);
}
