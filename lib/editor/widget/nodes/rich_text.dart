import 'dart:math';

import 'package:crayon/editor/core/editor_controller.dart';
import 'package:flutter/material.dart';
import '../../../../editor/extension/render_box.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../core/node_controller.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import '../../extension/offset.dart';
import '../../extension/painter.dart';

import '../../core/input_manager.dart';
import '../../core/logger.dart';
import '../../cursor/rich_text.dart';
import '../../cursor/node_position.dart';
import '../../node/rich_text/rich_text.dart';
import '../../shortcuts/arrows/arrows.dart';
import '../editing_cursor.dart';
import '../painter.dart';

class RichTextWidget extends StatefulWidget {
  const RichTextWidget(
    this.controller,
    this.richTextNode,
    this.position, {
    super.key,
    this.fontSize = 16,
  });

  final NodeController controller;
  final RichTextNode richTextNode;
  final SingleNodePosition? position;
  final double fontSize;

  @override
  State<RichTextWidget> createState() => _RichTextWidgetState();
}

class _RichTextWidgetState extends State<RichTextWidget> {
  final tag = 'RichText';

  final key = GlobalKey();

  final LayerLink layerLink = LayerLink();

  late TextPainter painter;

  RichTextNode get node => widget.richTextNode;

  late ValueNotifier<RichTextNodePosition?> editingCursorNotifier;
  late ValueNotifier<SelectingPosition?> selectingCursorNotifier;
  late ValueNotifier<RichTextNode> nodeChangedNotifier;

  double recordWidth = 0;

  TextSpan get textSpan => node.buildTextSpan();

  NodeController get controller => widget.controller;

  SingleNodePosition? get nodePosition => widget.position;

  ListenerCollection get listeners => controller.listeners;

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  @override
  void initState() {
    super.initState();
    editingCursorNotifier = ValueNotifier(editorPosition(nodePosition));
    selectingCursorNotifier = ValueNotifier(selectingPosition(nodePosition));
    nodeChangedNotifier = ValueNotifier(node);
    painter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      tryToUpdateInputAttribute(nodePosition);
      notifyEditingOffset(editorPosition(nodePosition));
    });
    listeners.addGestureListener(onGesture);
    listeners.addArrowDelegate(node.id, onArrowAccept);
  }

  @override
  void dispose() {
    super.dispose();
    listeners.removeGestureListener(onGesture);
    listeners.removeArrowDelegate(node.id, onArrowAccept);
    editingCursorNotifier.dispose();
    selectingCursorNotifier.dispose();
    nodeChangedNotifier.dispose();
    painter.dispose();
  }

  void onArrowAccept(AcceptArrowData data) {
    final type = data.type;
    final p = data.position;
    logger.i('$tag, onArrowAccept $data');
    if (p is! RichTextNodePosition) return;
    RichTextNodePosition? newPosition;
    switch (type) {
      case ArrowType.current:
        final extra = data.extras;
        if (extra is Offset) {
          final box = renderBox;
          if (box == null) return;
          final rect =
              Rect.fromPoints(Offset.zero, box.globalToLocal(Offset.zero));
          final textPosition = TextPosition(offset: node.getOffset(p));
          final h = painter.getFullHeightForCaret(textPosition, rect) ??
              widget.fontSize;
          final offset = painter.getOffsetFromTextOffset(node.getOffset(p));
          Offset? tapOffset;
          if (p == node.endPosition) {
            tapOffset = Offset(extra.dx, offset.dy + h / 2);
          } else if (p == node.beginPosition) {
            tapOffset = Offset(extra.dx, offset.dy + h / 2);
          }
          if (tapOffset == null) return;
          final globalOffset = box.localToGlobal(Offset.zero);
          final newTapOffset = tapOffset.move(globalOffset);
          listeners.notifyGesture(GestureState(GestureType.tap, newTapOffset));
        } else {
          newPosition = p;
        }
        break;
      case ArrowType.left:
        newPosition = node.lastPosition(p);
        break;
      case ArrowType.right:
        newPosition = node.nextPosition(p);
        break;
      case ArrowType.up:
        final box = renderBox;
        if (box == null) return;
        final rect =
            Rect.fromPoints(Offset.zero, box.globalToLocal(Offset.zero));
        final textPosition = TextPosition(offset: node.getOffset(p));
        final offset =
            painter.getOffsetFromTextOffset(node.getOffset(p), rect: rect);
        final lineRange = painter.getLineBoundary(textPosition);
        final h = painter.getFullHeightForCaret(textPosition, rect) ??
            widget.fontSize;
        if (lineRange.start == 0 || lineRange == TextRange.empty) {
          throw ArrowUpTopException(p, offset);
        }
        final newOffset = painter.getOffsetFromTextOffset(lineRange.start);
        final tapOffset = Offset(offset.dx, newOffset.dy - h / 2);
        final globalOffset = box.localToGlobal(Offset.zero);
        final newTapOffset = tapOffset.move(globalOffset);
        listeners.notifyGesture(GestureState(GestureType.tap, newTapOffset));
        break;
      case ArrowType.down:
        final box = renderBox;
        if (box == null) return;
        final rect =
            Rect.fromPoints(Offset.zero, box.globalToLocal(Offset.zero));
        final textPosition = TextPosition(offset: node.getOffset(p));
        final offset =
            painter.getOffsetFromTextOffset(node.getOffset(p), rect: rect);
        final lineRange = painter.getLineBoundary(textPosition);
        if (lineRange.end == node.spans.last.endOffset ||
            lineRange == TextRange.empty) {
          throw ArrowDownBottomException(p, offset);
        }
        final h = painter.getFullHeightForCaret(textPosition, rect) ??
            widget.fontSize;
        final newOffset = painter.getOffsetFromTextOffset(lineRange.end);
        final tapOffset = Offset(offset.dx, newOffset.dy + h / 2);
        final globalOffset = box.localToGlobal(Offset.zero);
        final newTapOffset = tapOffset.move(globalOffset);
        listeners.notifyGesture(GestureState(GestureType.tap, newTapOffset));
        break;
      default:
        break;
    }
    if (newPosition != null) {
      controller.notifyEditingPosition(newPosition);
      notifyEditingOffset(newPosition);
      updateInputAttribute(newPosition);
    }
  }

  double? get y => renderBox?.localToGlobal(Offset.zero).dy;

  void onPanUpdate(Offset global) {
    if (!containsOffset(global)) return;
    final box = renderBox;
    if (box == null) return;
    final widgetPosition = box.localToGlobal(Offset.zero);
    final localPosition =
        global.translate(-widgetPosition.dx, -widgetPosition.dy);
    final textPosition = painter.getPositionForOffset(localPosition);
    final richPosition = node.getPositionByOffset(textPosition.offset);
    controller.notifyPositionWhilePanGesture(richPosition);
  }

  void confirmToShowTextMenu(Offset offset) {
    final v = selectingCursorNotifier.value;
    if (v == null) return;
    if (!containsOffset(offset)) return;
    final left = v.left, right = v.right;
    if (left is! RichTextNodePosition || right is! RichTextNodePosition) return;
    bool isTextEmpty = node.getFromPosition(left, right).isEmpty;
    if (isTextEmpty) return;
    final h =
        painter.getFullHeightForCaret(buildTextPosition(offset), Rect.zero) ??
            widget.fontSize;
    controller.showOverlayEntry(
        TextMenuEntryShower(MenuInfo(offset, node.id, h), layerLink));
  }

  void confirmToShowLinkMenu(
      Offset offset, String url, SelectingPosition position) {
    final h =
        painter.getFullHeightForCaret(buildTextPosition(offset), Rect.zero) ??
            widget.fontSize;
    controller.showOverlayEntry(LinkEntryShower(
        MenuInfo(offset, node.id, h), layerLink,
        urlWithPosition: UrlWithPosition(
            url, controller.toCursor(position) as SelectingNodeCursor)));
  }

  bool containsOffset(Offset global) =>
      renderBox?.containsOffset(global) ?? false;

  void updatePainter() {
    painter.text = textSpan;
    painter.layout(maxWidth: recordWidth);
  }

  RichTextNodePosition? editorPosition(SingleNodePosition? position) {
    final p = position;
    if (p is EditingPosition) {
      return p.as<RichTextNodePosition>().position;
    }
    return null;
  }

  SelectingPosition? selectingPosition(SingleNodePosition? position) {
    final p = position;
    if (p is SelectingPosition) {
      return p;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant RichTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (node != oldWidget.richTextNode) {
      nodeChangedNotifier.value = node;
      updatePainter();
    }
    if (nodePosition != oldWidget.position) {
      final position = editorPosition(nodePosition);
      editingCursorNotifier.value = position;
      selectingCursorNotifier.value = selectingPosition(nodePosition);
      tryToUpdateInputAttribute(nodePosition);
      notifyEditingOffset(position);
    }
  }

  void notifyEditingOffset(RichTextNodePosition? position) {
    if (position != null && y != null) {
      final offset = painter.getOffsetFromTextOffset(position.offset);
      controller.notifyEditingOffset(EditingOffset(
          Offset(offset.dx, offset.dy + y!), getCurrentCursorHeight(position)));
    }
  }

  double getCurrentCursorHeight(RichTextNodePosition offset) {
    final rect = Rect.fromPoints(
        Offset.zero, renderBox?.globalToLocal(Offset.zero) ?? Offset.zero);
    return painter.getFullHeightForCaret(
            TextPosition(offset: node.getOffset(offset)), rect) ??
        widget.fontSize;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: LayoutBuilder(builder: (context, constrains) {
        if (recordWidth != constrains.maxWidth) {
          recordWidth = constrains.maxWidth;
          painter.layout(maxWidth: recordWidth);
        }
        return CompositedTransformTarget(
          link: layerLink,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
              key: key,
              height: max(painter.height, widget.fontSize),
              width: recordWidth,
              child: Stack(
                children: [
                  ValueListenableBuilder(
                      valueListenable: nodeChangedNotifier,
                      builder: (ctx, v, c) =>
                          Stack(children: painter.buildInlineCodes(v))),
                  SizedBox(
                    height: painter.height,
                    width: painter.width,
                    // child: RichText(text: textSpan),
                    child: CustomPaint(painter: RichTextPainter(painter)),
                  ),
                  ValueListenableBuilder(
                      valueListenable: editingCursorNotifier,
                      builder: (ctx, v, c) {
                        if (v == null) return Container();
                        final offset =
                            painter.getOffsetFromTextOffset(node.getOffset(v));
                        final textPosition =
                            TextPosition(offset: node.getOffset(v));
                        final h = painter.getFullHeightForCaret(
                                textPosition, Rect.zero) ??
                            widget.fontSize;
                        return Positioned(
                          left: offset.dx,
                          top: offset.dy,
                          child: EditingCursorWidget(
                            cursorColor: Colors.black,
                            cursorHeight: h,
                          ),
                        );
                      }),
                  ValueListenableBuilder(
                      valueListenable: selectingCursorNotifier,
                      builder: (ctx, v, c) {
                        if (v == null) return Container();
                        final left = v.left;
                        final right = v.right;
                        if (left is! RichTextNodePosition ||
                            right is! RichTextNodePosition) {
                          return Container();
                        }
                        final begin = node.getOffset(left);
                        final end = node.getOffset(right);
                        return Stack(
                            children: painter.buildSelectedAreas(begin, end));
                      }),
                  ValueListenableBuilder(
                      valueListenable: nodeChangedNotifier,
                      builder: (ctx, v, c) {
                        return Stack(
                            children: painter.buildLinkGestures(v,
                                onEnter: (o, s, p) {
                          final url = s.attributes['url'] ?? '';
                          confirmToShowLinkMenu(o, url, p);
                        }, onExit: (e) {
                          controller.entryManager.removeEntry();
                        }, onTap: (s) {
                          logger.i('$tag,  tapped:${s.text}');
                        }));
                      }),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  TextPosition buildTextPosition(Offset p) =>
      painter.buildTextPosition(p, renderBox);

  void onGesture(GestureState s) {
    switch (s.type) {
      case GestureType.tap:
        onTapped(s.globalOffset);
        break;
      case GestureType.panUpdate:
        onPanUpdate(s.globalOffset);
        break;
      case GestureType.hover:
        confirmToShowTextMenu(s.globalOffset);
        break;
    }
  }

  void onTapped(Offset globalOffset) {
    if (!containsOffset(globalOffset)) return;
    final off = buildTextPosition(globalOffset).offset;
    final richPosition = node.getPositionByOffset(off);
    // logger.i('_updatePosition, globalOffset:$globalOffset, off:$off');
    controller.notifyEditingPosition(richPosition);
    controller.notifyEditingOffset(
        EditingOffset(globalOffset, getCurrentCursorHeight(richPosition)));
    updateInputAttribute(richPosition);
  }

  void tryToUpdateInputAttribute(SingleNodePosition? position) {
    if (position is EditingPosition) {
      final p = position.position;
      if (p is RichTextNodePosition) updateInputAttribute(p);
    }
    // else if (position is SelectingPosition) {
    //   final p = position.left;
    //   if (p is RichTextNodePosition) updateInputAttribute(p);
    // }
  }

  void updateInputAttribute(RichTextNodePosition position) {
    final box = renderBox;
    if (box == null) return;
    final offset = painter.getOffsetFromTextOffset(node.getOffset(position));
    final height = painter.getFullHeightForCaret(
            TextPosition(offset: node.getOffset(position)), Rect.zero) ??
        widget.fontSize;
    controller.updateInputConnectionAttribute(InputConnectionAttribute(
        Rect.fromPoints(offset, offset.translate(0, height)),
        box.getTransformTo(null),
        box.size));
  }
}
