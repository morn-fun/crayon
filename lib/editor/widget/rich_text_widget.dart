import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import '../extension/offset_extension.dart';
import '../extension/painter_extension.dart';

import '../core/context.dart';
import '../core/controller.dart';
import '../core/input_manager.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import '../cursor/cursor_generator.dart';
import '../cursor/rich_text_cursor.dart';
import '../node/basic_node.dart';
import '../node/rich_text_node/rich_text_node.dart';
import '../shortcuts/arrows/arrows.dart';
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

  TextSpan get textSpan => node.buildTextSpanWithCursor(cursor, index);

  EditorContext get editorContext => widget.editorContext;

  RichEditorController get controller => editorContext.controller;

  InputManager get inputManager => editorContext.inputManager;

  int get index => widget.index;

  Offset _panOffset = Offset.zero;

  RenderBox? get renderBox =>
      key.currentContext?.findRenderObject() as RenderBox?;

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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      tryToUpdateInputAttribute(cursor);
    });
    controller.addTapDownCallback(node.id, _updatePosition);
    controller.addNodeChangedCallback(node.id, onNodeChanged);
    controller.addArrowDelegate(node.id, onArrowAccept);
    controller.addCursorChangedCallback(onCursorChanged);
    controller.addPanUpdateCallback(onPanUpdate);
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeNodeChangedCallback(node.id, onNodeChanged);
    controller.removeTapDownCallback(node.id, _updatePosition);
    controller.removeArrowDelegate(node.id, onArrowAccept);
    controller.removeCursorChangedCallback(onCursorChanged);
    controller.removePanUpdateCallback(onPanUpdate);
    painter.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void onCursorChanged(BasicCursor cursor) {
    bool needRefresh = _updateCursorThenCheckRefresh(cursor);
    if (needRefresh) {
      _updatePainter();
      refresh();
    }
  }

  void onArrowAccept(ArrowType type, NodePosition position) {
    logger.i('$tag, onArrowAccept type:$type, position:$position');
    final p = position as RichTextNodePosition;
    BasicCursor? newCursor;
    RichTextNodePosition? newPosition;
    switch (type) {
      case ArrowType.current:
        newPosition = position;
        newCursor = EditingCursor(index, newPosition);
        break;
      case ArrowType.left:
        newPosition = node.lastPosition(p);
        newCursor = EditingCursor(index, newPosition);
        break;
      case ArrowType.right:
        newPosition = node.nextPosition(p);
        newCursor = EditingCursor(index, newPosition);
        break;
      case ArrowType.up:
        final box = renderBox;
        if (box == null) return;
        final offsetWithLineHeight = painter.getOffsetWithLineHeight(
            TextPosition(offset: node.getOffset(position)),
            Rect.fromPoints(Offset.zero, box.globalToLocal(Offset.zero)));
        logger.i('$tag,  array up $offsetWithLineHeight');
        Offset offset = offsetWithLineHeight.offset;
        final height = offsetWithLineHeight.lineHeight;
        final globalOffset = box.localToGlobal(Offset.zero);
        if (offset.dy - height <= 0) {
          if (index > 0) {
            final lastNode = controller.getNode(index - 1);
            offset = offset.translate(0, -height).move(globalOffset);

            ///TODO:这里需要减去height和间距
            controller.notifyTapDown(lastNode.id, offset);
          }
        } else {
          offset = offset.translate(0, -height).move(globalOffset);
          controller.notifyTapDown(node.id, offset);
        }
        logger.i('$tag, $type,  newOffset:$offset, globalOff:$globalOffset');
        break;
      case ArrowType.down:
        final box = renderBox;
        if (box == null) return;
        final offsetWithLineHeight = painter.getOffsetWithLineHeight(
            TextPosition(offset: node.getOffset(position)),
            Rect.fromPoints(Offset.zero, box.globalToLocal(Offset.zero)));
        Offset offset = offsetWithLineHeight.offset;
        final height = offsetWithLineHeight.lineHeight;
        final globalOffset = box.localToGlobal(Offset.zero);
        final size = box.size;
        logger.i('$tag,  array down $offsetWithLineHeight');
        if (offset.dy + height >= size.height) {
          if (index < controller.nodeLength - 1) {
            final nextNode = controller.getNode(index + 1);
            offset = offset.translate(0, height).move(globalOffset);

            ///TODO:这里需要加上height和间距
            controller.notifyTapDown(nextNode.id, offset);
          }
        } else {
          offset = offset.translate(0, height).move(globalOffset);
          controller.notifyTapDown(node.id, offset);
        }
        logger.i(
            '$tag, $type,  newOffset:$offset, globalOffset:$globalOffset, size:$size');
        break;
      default:
        break;
    }
    if (newCursor != null) {
      controller.updateCursor(newCursor);
      if (newPosition != null) updateInputAttribute(newPosition);
    }
  }

  void onPanUpdate(Offset global) {
    final box = renderBox;
    if (box == null) return;
    final widgetPosition = box.localToGlobal(Offset.zero);
    final size = box.size;
    final localPosition =
        global.translate(-widgetPosition.dx, -widgetPosition.dy);
    bool contains = size.contains(localPosition);
    if (contains) {
      final textPosition = painter.getPositionForOffset(localPosition);
      final richPosition = node.getPositionByOffset(textPosition.offset);
      // logger.i(
      //     'onPanUpdate,  widget:$index, contains:$contains, textPosition:$textPosition, spanIndex:$spanIndex, span:$span');
      BasicCursor? newCursor =
          generateSelectingCursor(controller.cursor, richPosition, index);
      if (newCursor != null) controller.updateCursor(newCursor);
    }
  }

  void onNodeChanged(EditorNode node) {
    if (node is! RichTextNode || node.id != this.node.id) return;
    this.node = node;
    _updateCursorThenCheckRefresh(controller.cursor);
    _updatePainter();
    refresh();
  }

  void _updatePainter() {
    painter.text = textSpan;
    painter.layout(maxWidth: recordWidth);
  }

  bool _updateCursorThenCheckRefresh(BasicCursor cursor) {
    bool hasCursorTypeChanged = this.cursor.runtimeType != cursor.runtimeType;
    this.cursor = cursor;
    final newNodePosition = getNodePosition(cursor);
    if (positionNotifier.value != newNodePosition) {
      positionNotifier.value = newNodePosition;
    }
    bool needRefresh = tryToUpdateInputAttribute(cursor);
    // logger.i(
    //     '_updateCursor,  index:$index,  needRefresh:$needRefresh,  hasCursorTypeChanged:$hasCursorTypeChanged, cursor:$cursor');
    return needRefresh || hasCursorTypeChanged;
  }

  RichTextNodePosition? getNodePosition(BasicCursor cursor) {
    if (cursor is! EditingCursor) return null;
    final theNode = controller.getNode(cursor.index);
    if (theNode is RichTextNode? && theNode.id == node.id) {
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
        controller.notifyTapDown(node.id, detail.globalPosition);
      },
      onPanStart: (d) {
        _panOffset = d.globalPosition;
      },
      onPanEnd: (d) {
        EasyThrottle.cancel(node.id);
        controller.notifyDragUpdateDetails(_panOffset);
      },
      onPanUpdate: (d) {
        _panOffset = _panOffset.translate(d.delta.dx, d.delta.dy);
        EasyThrottle.throttle(node.id, const Duration(milliseconds: 50), () {
          controller.notifyDragUpdateDetails(d.globalPosition);
        });
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
                  child: MouseRegion(
                      cursor: SystemMouseCursors.text,
                      child: CustomPaint(painter: _TextPainter(painter))),
                ),
                ValueListenableBuilder(
                    valueListenable: positionNotifier,
                    builder: (ctx, v, c) {
                      if (v == null) return Container();
                      final offset =
                          painter.getOffsetFromTextOffset(node.getOffset(v));
                      double cursorHeight = painter.getFullHeightForCaret(
                              TextPosition(offset: node.getOffset(v)),
                              Rect.zero) ??
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
    final box = renderBox;
    if (box == null) return const TextPosition(offset: 0);
    final widgetPosition = box.localToGlobal(Offset.zero);
    final localPosition =
        globalPosition.translate(-widgetPosition.dx, -widgetPosition.dy);
    return painter.getPositionForOffset(localPosition);
  }

  void _updatePosition(Offset globalOffset) {
    final off = buildTextPosition(globalOffset).offset;
    final richPosition = node.getPositionByOffset(off);
    // logger.i(
    //     '_updatePosition, globalOffset:$globalOffset, off:$off, index:$spanIndex, span:$span');
    final newCursor = EditingCursor(index, richPosition);
    controller.updateCursor(newCursor);
    updateInputAttribute(newCursor.position);
  }

  bool tryToUpdateInputAttribute(BasicCursor cursor) {
    bool needRefresh = false;
    if (cursor is EditingCursor &&
        cursor.position is RichTextNodePosition &&
        cursor.index == index) {
      updateInputAttribute(cursor.position as RichTextNodePosition);
      needRefresh = true;
    } else if (cursor is SelectingNodeCursor && cursor.index == index) {
      final begin = cursor.begin;
      if (begin is RichTextNodePosition) updateInputAttribute(begin);
      needRefresh = true;
    } else if (cursor is SelectingNodesCursor) {
      final position = cursor.beginPosition;
      if (cursor.beginIndex == index && position is RichTextNodePosition) {
        updateInputAttribute(position);
      }
      needRefresh = true;
    }
    return needRefresh;
  }

  void updateInputAttribute(RichTextNodePosition position) {
    if (key.currentContext == null) return;
    final box = key.currentContext!.findRenderObject() as RenderBox;
    final offsetWithLineHeight = painter.getOffsetWithLineHeight(
        TextPosition(offset: node.getOffset(position)),
        Rect.fromPoints(Offset.zero, box.globalToLocal(Offset.zero)));
    final offset = offsetWithLineHeight.offset
        .translate(0, offsetWithLineHeight.lineHeight);
    inputManager.updateInputConnectionAttribute(InputConnectionAttribute(
        Rect.fromPoints(offset, offset), box.getTransformTo(null), box.size));
    inputManager.requestFocus();
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
