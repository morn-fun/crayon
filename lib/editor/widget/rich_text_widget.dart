import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/controller.dart';
import '../core/input_manager.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../cursor/rich_text_cursor.dart';
import '../node/basic_node.dart';
import '../node/rich_text_node/rich_text_node.dart';
import 'editing_cursor.dart';

class RichTextWidget extends StatefulWidget {
  const RichTextWidget(this.editorContext, this.richTextNode, this.index,
      {super.key});

  final EditorContext editorContext;
  final RichTextNode richTextNode;
  final int index;

  @override
  State<RichTextWidget> createState() => _RichTextWidgetState();
}

class _RichTextWidgetState extends State<RichTextWidget> {
  final tag = 'RichTextPainter';

  final key = GlobalKey();

  late TextPainter painter;

  late RichTextNode node;

  late BasicCursor cursor;

  late ValueNotifier<RichTextNodePosition?> positionNotifier;

  double recordWidth = 0;

  TextSpan get textSpan {
    final c = cursor;
    if (c is SelectingNodeCursor<RichTextNodePosition>) {
      if (c.index == index) {
        return node.selectingTextSpan(c.begin, c.end);
      }
    } else if (c is SelectingNodesCursor) {
      // if(c.beginIndex < index && c.endIndex < index){
      //   return node.selectingTextSpan(node.beginPosition, node.endPosition);
      // } else if (c.beginIndex == index) {
      //   final position = c.beginPosition as RichTextNodePosition;
      //   return
      // } else if (c.endIndex == index) {
      //
      // }
    }
    return node.textSpan;
  }

  EditorContext get editorContext => widget.editorContext;

  RichEditorController get controller => editorContext.controller;

  InputManager get inputManager => editorContext.inputManager;

  int get index => widget.index;

  @override
  void initState() {
    super.initState();
    node = widget.richTextNode;
    cursor = controller.cursor;
    positionNotifier = ValueNotifier(getNodePosition(cursor));
    painter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
    );
    controller.addCursorChangedCallback(onCursorChanged);
    controller.addNodeChangedCallback(node.id, onNodeChanged);
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeCursorChangedCallback(onCursorChanged);
    controller.removeNodeChangedCallback(node.id, onNodeChanged);
    painter.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void onCursorChanged(BasicCursor cursor) {
    _updateCursor(cursor);
    // refresh();
  }

  void onNodeChanged(EditorNode node) {
    if (node is! RichTextNode || node.id != this.node.id) return;
    this.node = node;
    painter.text = textSpan;
    painter.layout(maxWidth: recordWidth);
    if (cursor != controller.cursor) {
      _updateCursor(controller.cursor);
    }
    refresh();
  }

  void _updateCursor(BasicCursor cursor) {
    if (this.cursor != cursor) {
      this.cursor = cursor;
      positionNotifier.value = getNodePosition(cursor);
    }
  }

  RichTextNodePosition? getNodePosition(BasicCursor cursor) {
    if (cursor is! EditingCursor) return null;
    final theNode = controller.getNode(cursor.index);
    if (theNode is RichTextNode? && theNode?.id == node.id) {
      return cursor.position as RichTextNodePosition;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant RichTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (node != widget.richTextNode) {
      onNodeChanged(widget.richTextNode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (detail) {
        _updatePosition(buildTextPosition(detail.globalPosition).offset);
      },
      onPanEnd: (d) {
        print('onPanEnd--- ${node.spans.map((e) => e.text).join(',')} $d');
      },
      onPanUpdate: (d) {
        print('onPanUpdate---${node.spans.map((e) => e.text).join(',')}   $d');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(builder: (context, constrains) {
          if (recordWidth != constrains.maxWidth) {
            recordWidth = constrains.maxWidth;
            painter.layout(maxWidth: recordWidth);
          }
          return SizedBox(
            key: key,
            height: painter.height,
            width: painter.width,
            child: Stack(
              children: [
                SizedBox(
                  height: painter.height,
                  width: painter.width,
                  child: CustomPaint(painter: _TextPainter(painter)),
                ),
                ValueListenableBuilder(
                    valueListenable: positionNotifier,
                    builder: (ctx, v, c) {
                      if (v == null) return Container();
                      final textPosition = TextPosition(offset: v.offset);
                      final offset =
                          painter.getOffsetForCaret(textPosition, Rect.zero);
                      double cursorHeight = painter.getFullHeightForCaret(
                              textPosition, Rect.zero) ??
                          16;
                      return Positioned(
                        left: offset.dx,
                        top: offset.dy,
                        child: EditingCursorWidget(
                          cursorColor: Colors.black,
                          cursorHeight: cursorHeight,
                        ),
                      );
                    }),
              ],
            ),
          );
        }),
      ),
    );
  }

  TextPosition buildTextPosition(Offset globalPosition) {
    final box = key.currentContext!.findRenderObject() as RenderBox;
    final widgetPosition = box.localToGlobal(Offset.zero);
    final localPosition = Offset(globalPosition.dx - widgetPosition.dx,
        globalPosition.dy - widgetPosition.dy);
    final p = painter.getPositionForOffset(localPosition);
    return p;
  }

  void _updatePosition(int off) {
    var spanIndex = node.locateSpanIndex(off);
    final newCursor =
        EditingCursor(index, RichTextNodePosition(spanIndex, off));
    controller.updateCursor(newCursor);
    updateInputAttribute(newCursor);
  }

  void updateInputAttribute(EditingCursor<RichTextNodePosition> cursor) {
    final position = cursor.position;
    final textPosition = TextPosition(offset: position.offset);
    final box = key.currentContext!.findRenderObject() as RenderBox;
    Offset offset = painter.getOffsetForCaret(textPosition,
        Rect.fromPoints(Offset.zero, box.globalToLocal(Offset.zero)));
    final lineHeight =
        painter.getFullHeightForCaret(textPosition, Rect.zero) ?? 16;
    offset = offset.translate(0, lineHeight);
    inputManager.updateInputConnectionAttribute(InputConnectionAttribute(
        Rect.fromPoints(offset, offset), box.getTransformTo(null), box.size));
  }
}

class _TextPainter extends CustomPainter {
  final TextPainter _painter;

  _TextPainter(this._painter);

  @override
  void paint(Canvas canvas, Size size) {
    Rect background = Rect.fromLTWH(0, 0, size.width, size.height);
    Paint backgroundPaint = Paint()..color = const Color(0xFF8BC34A);
    canvas.drawRect(background, backgroundPaint);
    _painter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
