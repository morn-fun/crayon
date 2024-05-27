import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../editor/extension/render_box.dart';
import '../../core/context.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import '../../extension/offset.dart';
import '../../extension/painter.dart';
import '../../core/logger.dart';
import '../../cursor/rich_text.dart';
import '../../node/rich_text/rich_text.dart';
import '../../shortcuts/arrows/arrows.dart';
import '../editing_cursor.dart';
import '../editor/shared_node_context_widget.dart';
import '../menu/link.dart';
import '../painter.dart';
import '../../../editor/core/editor_controller.dart';

class RichTextWidget extends StatefulWidget {
  const RichTextWidget(
    this.operator,
    this.richTextNode,
    this.param, {
    super.key,
    this.fontSize = 16,
  });

  final NodesOperator operator;
  final RichTextNode richTextNode;
  final NodeBuildParam param;
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
  late ValueNotifier<SelectingNodeCursor?> selectingCursorNotifier;
  late ValueNotifier<RichTextNode> nodeChangedNotifier;

  double recordWidth = 0;

  TextSpan get textSpan => node.buildTextSpan();

  NodesOperator get operator => widget.operator;

  SingleNodeCursor? get nodeCursor => widget.param.cursor;

  ListenerCollection get listeners => operator.listeners;

  int get nodeIndex => widget.param.index;

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  @override
  void initState() {
    super.initState();
    editingCursorNotifier = ValueNotifier(editorPosition(nodeCursor));
    selectingCursorNotifier = ValueNotifier(selectingPosition(nodeCursor));
    nodeChangedNotifier = ValueNotifier(node);
    painter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyEditingOffset(editorPosition(nodeCursor));
    });
    listeners.addGestureListener(node.id, onGesture);
    listeners.addArrowDelegate(node.id, onArrowAccept);
  }

  @override
  void dispose() {
    super.dispose();
    listeners.removeGestureListener(node.id, onGesture);
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
          listeners.notifyGestures(TapGestureState(newTapOffset));
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
        listeners.notifyGestures(TapGestureState(newTapOffset));
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
        listeners.notifyGestures(TapGestureState(newTapOffset));
        break;
      default:
        break;
    }
    if (newPosition != null) {
      operator.onCursor(EditingCursor(nodeIndex, newPosition));
      notifyEditingOffset(newPosition);
    }
  }

  double? get y => renderBox?.localToGlobal(Offset.zero).dy;

  bool onPanUpdate(Offset global) {
    if (!containsOffset(global)) return false;
    final box = renderBox;
    if (box == null) return false;
    final widgetPosition = box.localToGlobal(Offset.zero);
    final localPosition =
        global.translate(-widgetPosition.dx, -widgetPosition.dy);
    final textPosition = painter.getPositionForOffset(localPosition);
    final richPosition = node.getPositionByOffset(textPosition.offset);
    operator.onPanUpdate(EditingCursor(nodeIndex, richPosition));
    return true;
  }

  bool confirmToShowTextMenu(Offset offset) {
    final v = selectingCursorNotifier.value;
    if (v == null) return false;
    if (!containsOffset(offset)) return false;
    final left = v.left, right = v.right;
    if (left is! RichTextNodePosition || right is! RichTextNodePosition) {
      return false;
    }
    final entryManager =
        ShareEditorContextWidget.of(context)?.context.entryManager;
    if (entryManager == null) return true;
    if (entryManager.showingType != null) return true;
    bool isTextEmpty = node.getFromPosition(left, right).isEmpty;
    if (isTextEmpty) return true;
    final h =
        painter.getFullHeightForCaret(buildTextPosition(offset), Rect.zero) ??
            widget.fontSize;
    final box = renderBox;
    if (box == null) return true;
    entryManager.showTextMenu(Overlay.of(context),
        MenuInfo(box.globalToLocal(offset), node.id, h, layerLink), operator);
    return true;
  }

  bool containsOffset(Offset global) =>
      renderBox?.containsOffset(global) ?? false;

  void updatePainter() {
    painter.text = textSpan;
    painter.layout(maxWidth: recordWidth);
  }

  RichTextNodePosition? editorPosition(SingleNodeCursor? cursor) {
    if (cursor is EditingCursor && cursor.position is RichTextNodePosition) {
      return cursor.position as RichTextNodePosition;
    }
    return null;
  }

  SelectingNodeCursor? selectingPosition(SingleNodeCursor? cursor) {
    if (cursor is SelectingNodeCursor) {
      return cursor;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant RichTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldListeners = oldWidget.operator.listeners;
    if (oldListeners.hashCode != listeners.hashCode) {
      oldListeners.removeGestureListener(node.id, onGesture);
      oldListeners.removeArrowDelegate(node.id, onArrowAccept);
      listeners.addGestureListener(node.id, onGesture);
      listeners.addArrowDelegate(node.id, onArrowAccept);
      logger.i(
          '${node.runtimeType} onListenerChanged:${oldListeners.hashCode},  newListener:${listeners.hashCode}');
    }
    if (node != oldWidget.richTextNode) {
      nodeChangedNotifier.value = node;
      updatePainter();
    }
    if (nodeCursor != oldWidget.param.cursor) {
      final position = editorPosition(nodeCursor);
      editingCursorNotifier.value = position;
      selectingCursorNotifier.value = selectingPosition(nodeCursor);
      notifyEditingOffset(position);
    }
  }

  void notifyEditingOffset(RichTextNodePosition? position) {
    final box = renderBox;
    if (box == null) return;
    if (position != null && y != null) {
      final offset = painter.getOffsetFromTextOffset(position.offset);
      final newOffset =
          Offset(offset.dx + box.localToGlobal(Offset.zero).dx, offset.dy + y!);
      operator.onEditingOffset(
          EditingOffset(newOffset, getCurrentCursorHeight(position), node.id));
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
    final editorContext = ShareEditorContextWidget.of(context)?.context;
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
            key: key,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
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
                        final Set<String> hoveredNodeIds = {};
                        return LinkHover(
                            node: v,
                            nodeIndex: nodeIndex,
                            painter: painter,
                            onEnter: (o, s, p) {
                              hoveredNodeIds.add(node.id);
                              final url = s.attributes['url'] ?? '';
                              final alias = s.attributes['alias'] ?? '';
                              final h = painter.getFullHeightForCaret(
                                      buildTextPosition(o), Rect.zero) ??
                                  widget.fontSize;
                              final entryManager = editorContext?.entryManager;
                              if (entryManager == null) return;
                              if (entryManager.showingType == MenuType.link) {
                                return;
                              }
                              entryManager.showLinkMenu(
                                  Overlay.of(context),
                                  LinkMenuInfo(
                                      MenuInfo(o, node.id, h, layerLink),
                                      p.as<RichTextNodePosition>(),
                                      UrlInfo(url, alias), hoveredNodeIds),
                                  operator);
                            },
                            onExit: (e) => hoveredNodeIds.remove(node.id),
                            onTap: (s) {
                              logger.i('$tag,  tapped:${s.text}');
                            });
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

  bool onGesture(GestureState s) {
    if (s is TapGestureState) {
      return onTapped(s.globalOffset);
    } else if (s is HoverGestureState) {
      return confirmToShowTextMenu(s.globalOffset);
    } else if (s is PanGestureState) {
      return onPanUpdate(s.globalOffset);
    }
    return false;
  }

  bool onTapped(Offset globalOffset) {
    if (!containsOffset(globalOffset)) return false;
    final off = buildTextPosition(globalOffset).offset;
    final richPosition = node.getPositionByOffset(off);
    // logger.i('_updatePosition, globalOffset:$globalOffset, off:$off');
    operator.onCursor(EditingCursor(nodeIndex, richPosition));
    operator.onEditingOffset(EditingOffset(
        globalOffset, getCurrentCursorHeight(richPosition), node.id));
    return true;
  }
}
