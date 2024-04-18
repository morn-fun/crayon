import 'package:flutter/material.dart';
import '../core/entry_manager.dart';
import '../core/listener_collection.dart';
import '../core/node_controller.dart';
import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import '../extension/offset_extension.dart';
import '../extension/painter_extension.dart';

import '../core/input_manager.dart';
import '../core/logger.dart';
import '../cursor/rich_text_cursor.dart';
import '../node/position_data.dart';
import '../node/rich_text_node/rich_text_node.dart';
import '../shortcuts/arrows/arrows.dart';
import 'editing_cursor.dart';

class RichText extends StatefulWidget {
  const RichText(
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
  State<RichText> createState() => _RichTextState();
}

class _RichTextState extends State<RichText> {
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
    listeners.addEntryStatusChangedListener(onEntryStatus);
    listeners.addArrowDelegate(node.id, onArrowAccept);
  }

  @override
  void dispose() {
    super.dispose();
    listeners.removeGestureListener(onGesture);
    listeners.removeEntryStatusChangedListener(onEntryStatus);
    listeners.removeArrowDelegate(node.id, onArrowAccept);
    editingCursorNotifier.dispose();
    selectingCursorNotifier.dispose();
    nodeChangedNotifier.dispose();
    painter.dispose();
  }

  void onEntryStatus(EntryStatus s) {
    if (s != EntryStatus.readyToShowingOptionalMenu) return;
    final box = renderBox;
    if (box == null) return;
    final v = editingCursorNotifier.value;
    if (v == null) return;
    controller
        .showOverlayEntry(OptionalEntryShower(box.localToGlobal(Offset.zero)));
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
    if (controller.entryStatus != EntryStatus.idle) return;
    if (!containsOffset(offset)) return;
    final left = v.left, right = v.right;
    if (left is! RichTextNodePosition || right is! RichTextNodePosition) return;
    bool isTextEmpty = node.getFromPosition(left, right).isEmpty;
    if (isTextEmpty) return;
    controller.updateEntryStatus(EntryStatus.readyToShowingTextMenu);
    final h =
        painter.getFullHeightForCaret(buildTextPosition(offset), Rect.zero) ??
            widget.fontSize;
    controller.showOverlayEntry(
        TextMenuEntryShower(MenuInfo(offset, node.id, h), layerLink));
  }

  void confirmToShowLinkMenu(
      Offset offset, String url, SelectingPosition position) {
    if (controller.entryStatus != EntryStatus.idle) return;
    controller.updateEntryStatus(EntryStatus.readyToShowingLinkMenu);
    final h =
        painter.getFullHeightForCaret(buildTextPosition(offset), Rect.zero) ??
            widget.fontSize;
    controller.showOverlayEntry(LinkEntryShower(
        MenuInfo(offset, node.id, h), layerLink,
        urlWithPosition: UrlWithPosition(
            url, controller.toCursor(position) as SelectingNodeCursor)));
  }

  bool containsOffset(Offset global) {
    final box = renderBox;
    if (box == null) return false;
    final widgetPosition = box.localToGlobal(Offset.zero);
    final size = box.size;
    final localPosition =
        global.translate(-widgetPosition.dx, -widgetPosition.dy);
    return size.contains(localPosition);
  }

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
  void didUpdateWidget(covariant RichText oldWidget) {
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
      final cursorY = painter.getOffsetFromTextOffset(position.offset).dy;
      controller.notifyEditingOffset(cursorY + y!);
    }
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
          child: SizedBox(
            key: key,
            height: painter.height,
            width: painter.width,
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
                  child: CustomPaint(painter: _TextPainter(painter)),
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
                      return Stack(
                          children: painter.buildSelectedAreas(v, node));
                    }),
                ValueListenableBuilder(
                    valueListenable: nodeChangedNotifier,
                    builder: (ctx, v, c) {
                      return Stack(
                          children:
                              painter.buildLinkGestures(v, onEnter: (o, s, p) {
                        final url = s.attributes['url'] ?? '';
                        controller.updateEntryStatus(EntryStatus.idle);
                        confirmToShowLinkMenu(o, url, p);
                      }, onExit: (e) {
                        Future.delayed(Duration(milliseconds: 200), () {
                          if (controller.entryStatus ==
                                  EntryStatus.showingLinkMenu &&
                              mounted) {
                            controller.entryManager.hideMenu();
                          }
                        });
                      }, onTap: (s) {
                        logger.i('$tag,  tapped:${s.text}');
                      }));
                    }),
              ],
            ),
          ),
        );
      }),
    );
  }

  TextPosition buildTextPosition(Offset globalPosition) {
    final box = renderBox;
    if (box == null) return const TextPosition(offset: 0);
    final widgetPosition = box.localToGlobal(Offset.zero);
    final localPosition =
        globalPosition.translate(-widgetPosition.dx, -widgetPosition.dy);
    logger.i('$tag, buildTextPosition, localPosition:$localPosition');
    return painter.getPositionForOffset(localPosition);
  }

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
    logger.i('_updatePosition, globalOffset:$globalOffset, off:$off');
    controller.notifyEditingPosition(richPosition);
    controller.notifyEditingOffset(globalOffset.dy);
    updateInputAttribute(richPosition);
  }

  void tryToUpdateInputAttribute(SingleNodePosition? position) {
    if (position is EditingPosition) {
      final p = position.position;
      if (p is RichTextNodePosition) updateInputAttribute(p);
    } else if (position is SelectingPosition) {
      final p = position.left;
      if (p is RichTextNodePosition) updateInputAttribute(p);
    }
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

class _TextPainter extends CustomPainter {
  final TextPainter _painter;

  _TextPainter(this._painter);

  @override
  void paint(Canvas canvas, Size size) {
    Rect background = Rect.fromLTWH(0, 0, size.width, size.height);
    Paint backgroundPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(background, backgroundPaint);
    _painter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
