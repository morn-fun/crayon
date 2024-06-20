import 'dart:math';

import 'package:flutter/material.dart';
import '../../../editor/extension/render_box.dart';
import '../../command/modification.dart';
import '../../core/context.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import '../../extension/painter.dart';
import '../../core/logger.dart';
import '../../cursor/rich_text.dart';
import '../../node/basic.dart';
import '../../node/rich_text/rich_text.dart';
import '../../node/rich_text/rich_text_span.dart';
import '../../shortcuts/arrows/arrows.dart';
import '../../shortcuts/styles.dart';
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

  double get fontSize => widget.fontSize;

  String get nodeId => node.id;

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  @override
  void initState() {
    super.initState();
    logger.i('$runtimeType $nodeId  init');
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
    listeners.addGestureListener(nodeId, onGesture);
    listeners.addArrowDelegate(nodeId, onArrowAccept);
  }

  @override
  void dispose() {
    super.dispose();
    listeners.removeGestureListener(nodeId, onGesture);
    listeners.removeArrowDelegate(nodeId, onArrowAccept);
    editingCursorNotifier.dispose();
    selectingCursorNotifier.dispose();
    nodeChangedNotifier.dispose();
    painter.dispose();
  }

  void onArrowAccept(AcceptArrowData data) {
    final type = data.type;
    late RichTextNodePosition p;
    final cursor = data.cursor;
    if (cursor.position is! RichTextNodePosition) return;
    p = cursor.position as RichTextNodePosition;
    logger.i('$tag, onArrowAccept $data');
    RichTextNodePosition? newPosition;
    bool isSelection = false;
    switch (type) {
      case ArrowType.current:
      case ArrowType.selectionCurrent:
        isSelection = type == ArrowType.selectionCurrent;
        final extra = data.extras;
        if (extra is Offset) {
          final lineRange =
              painter.getLineBoundary(TextPosition(offset: node.getOffset(p)));
          final startOff = painter.getOffsetFromTextOffset(lineRange.start),
              endOff = painter.getOffsetFromTextOffset(lineRange.end);
          Offset tapOffset = Offset(extra.dx, (startOff.dy + endOff.dy) / 2);
          final position = painter.getPositionForOffset(tapOffset);
          newPosition = node.getPositionByOffset(position.offset);
        } else {
          newPosition = p;
        }
        break;
      case ArrowType.left:
      case ArrowType.selectionLeft:
        isSelection = type == ArrowType.selectionLeft;
        newPosition = node.lastPosition(p);
        break;
      case ArrowType.right:
      case ArrowType.selectionRight:
        isSelection = type == ArrowType.selectionRight;
        newPosition = node.nextPosition(p);
        break;
      case ArrowType.up:
      case ArrowType.selectionUp:
        isSelection = type == ArrowType.selectionUp;
        final box = renderBox;
        if (box == null) return;
        final rect =
            Rect.fromPoints(Offset.zero, box.globalToLocal(Offset.zero));
        final textPosition = TextPosition(offset: node.getOffset(p));
        final offset = painter.getOffsetFromTextOffset(node.getOffset(p));
        final lineRange = painter.getLineBoundary(textPosition);
        final h = painter.getFullHeightForCaret(textPosition, rect) ?? fontSize;
        if (lineRange.start == 0 || lineRange == TextRange.empty) {
          throw ArrowUpTopException(p, offset);
        }
        final startOff = painter.getOffsetFromTextOffset(lineRange.start),
            endOff = painter.getOffsetFromTextOffset(lineRange.end);
        final tapOffset = Offset(offset.dx, (startOff.dy + endOff.dy) / 2 - h);
        final position = painter.getPositionForOffset(tapOffset);
        newPosition = node.getPositionByOffset(position.offset);
        break;
      case ArrowType.down:
      case ArrowType.selectionDown:
        isSelection = type == ArrowType.selectionDown;
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
        final h = painter.getFullHeightForCaret(textPosition, rect) ?? fontSize;
        final startOff = painter.getOffsetFromTextOffset(lineRange.start),
            endOff = painter.getOffsetFromTextOffset(lineRange.end);
        final tapOffset = Offset(offset.dx, (startOff.dy + endOff.dy) / 2 + h);
        final position = painter.getPositionForOffset(tapOffset);
        newPosition = node.getPositionByOffset(position.offset);
        break;
      case ArrowType.wordLast:
      case ArrowType.selectionWordLast:
        isSelection = type == ArrowType.selectionWordLast;
        if (p == node.beginPosition) throw ArrowLeftBeginException(p);
        final currentOffset = node.getOffset(p);
        var wordRange =
            painter.getWordBoundary(TextPosition(offset: currentOffset));
        if (wordRange.start == currentOffset) {
          wordRange =
              painter.getWordBoundary(TextPosition(offset: currentOffset - 1));
        }
        newPosition = node.getPositionByOffset(wordRange.start);
        break;
      case ArrowType.wordNext:
      case ArrowType.selectionWordNext:
        isSelection = type == ArrowType.selectionWordNext;
        if (p == node.endPosition) throw ArrowRightEndException(p);
        final currentOffset = node.getOffset(p);
        var wordRange =
            painter.getWordBoundary(TextPosition(offset: node.getOffset(p)));
        if (wordRange.end == currentOffset) {
          wordRange =
              painter.getWordBoundary(TextPosition(offset: currentOffset + 1));
        }
        newPosition = node.getPositionByOffset(wordRange.end);
        break;
      case ArrowType.lineBegin:
        final currentOffset = node.getOffset(p);
        var lineRange =
            painter.getLineBoundary(TextPosition(offset: currentOffset));
        if (lineRange.start == currentOffset) {
          throw NodeUnsupportedException(node.runtimeType,
              'lineBegin is disabled, now is in lineBegin', data);
        }
        newPosition = node.getPositionByOffset(lineRange.start);
        break;
      case ArrowType.lineEnd:
        final currentOffset = node.getOffset(p);
        var lineRange =
            painter.getLineBoundary(TextPosition(offset: node.getOffset(p)));
        if (lineRange.end == currentOffset) {
          throw NodeUnsupportedException(
              node.runtimeType, 'lineEnd is disabled, now is in lineEnd', data);
        }
        newPosition = node.getPositionByOffset(lineRange.end);
        break;
      default:
        break;
    }
    if (newPosition == null) return;
    if (isSelection) {
      operator.onPanUpdate(EditingCursor(nodeIndex, newPosition));
      notifyEditingOffset(newPosition);
      return;
    }
    operator.onCursor(EditingCursor(nodeIndex, newPosition));
    notifyEditingOffset(newPosition);
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
    operator.onCursorOffset(
        EditingOffset(global, getCurrentCursorHeight(richPosition), nodeId));
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
    final textBoxList = painter.getBoxesForSelection(TextSelection(
        baseOffset: node.getOffset(left), extentOffset: node.getOffset(right)));
    if (textBoxList.isEmpty) return true;
    final first = textBoxList.first.toRect().bottomLeft;
    final last = textBoxList.last.toRect().bottomRight;
    final x = (first.dx + last.dx) / 2;
    final screenSize = MediaQuery.of(context).size;
    final y = max(max(0.0, first.dy), min(screenSize.height, last.dy));
    final localOffset = Offset(x, y);
    entryManager.showTextMenu(
        Overlay.of(context),
        MenuInfo(localOffset, renderBox?.localToGlobal(localOffset) ?? offset,
            nodeId, layerLink),
        operator);
    return true;
  }

  bool containsOffset(Offset global) =>
      renderBox?.containsY(global.dy) ?? false;

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
    final oldId = oldWidget.richTextNode.id;
    final oldListeners = oldWidget.operator.listeners;
    if (oldId != nodeId || oldListeners.hashCode != listeners.hashCode) {
      logger.i('$runtimeType didUpdateWidget oldId:$oldId,  id:$nodeId');
      oldListeners.removeGestureListener(oldId, onGesture);
      oldListeners.removeArrowDelegate(oldId, onArrowAccept);
      listeners.addGestureListener(nodeId, onGesture);
      listeners.addArrowDelegate(nodeId, onArrowAccept);
    }
    if (oldListeners.hashCode != listeners.hashCode) {
      logger.i('$runtimeType didUpdateWidget listeners is different');
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
    if (position != null) {
      final textOffset = painter.getOffsetFromTextOffset(position.offset);
      final localOffset = box.localToGlobal(Offset.zero);
      final newOffset = localOffset + textOffset;
      operator.onCursorOffset(
          EditingOffset(newOffset, getCurrentCursorHeight(position), nodeId));
    }
  }

  double getCurrentCursorHeight(RichTextNodePosition offset) {
    final rect = Rect.fromPoints(
        Offset.zero, renderBox?.globalToLocal(Offset.zero) ?? Offset.zero);
    return painter.getFullHeightForCaret(
            TextPosition(offset: node.getOffset(offset)), rect) ??
        fontSize;
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
          if (recordWidth == double.infinity) recordWidth = painter.width + 2;
        }
        return CompositedTransformTarget(
          link: layerLink,
          child: Padding(
            key: key,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
              height: max(painter.height, fontSize),
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
                            fontSize * 1.5;
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
                        if (begin == end) {
                          final h = painter.getFullHeightForCaret(
                                  TextPosition(offset: begin), Rect.zero) ??
                              fontSize * 1.5;
                          Offset offset =
                              painter.getOffsetFromTextOffset(begin);
                          return Positioned(
                            left: offset.dx,
                            top: offset.dy,
                            child: Container(
                                height: h,
                                width: 2,
                                color: Colors.blue.withOpacity(0.5)),
                          );
                        }
                        return Stack(
                            children: painter.buildSelectedAreas(begin, end));
                      }),
                  ValueListenableBuilder(
                      valueListenable: nodeChangedNotifier,
                      builder: (ctx, v, c) {
                        final entryManager = editorContext?.entryManager;
                        return LinkHover(
                          node: v,
                          painter: painter,
                          enableToShow: () => entryManager?.showingType == null,
                          onEdit: (s) {
                            if (entryManager == null) return;
                            if (entryManager.showingType == MenuType.link) {
                              return;
                            }
                            entryManager.showLinkMenu(
                                Overlay.of(context), s, operator);
                          },
                          onTap: (s) {
                            logger.i('$tag,  tapped:${s.text}');
                          },
                          layerLink: layerLink,
                          widgetIndex: nodeIndex,
                          onCancel: (s) {
                            onStyleEvent(
                                operator, RichTextTag.link, operator.cursor,
                                attributes: {});
                            final r = node.onSelect(SelectingData(
                                s, EventType.link, operator,
                                extras: StyleExtra(true, {})));
                            operator.execute(
                                ModifyNode(NodeWithCursor(r.node, r.cursor)));
                          },
                        );
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
    } else if (s is DoubleTapGestureState) {
      return onDoubleTap(s.globalOffset);
    } else if (s is TripleTapGestureState) {
      return onTripleTap(s.globalOffset);
    }
    return false;
  }

  bool onTapped(Offset globalOffset) {
    if (!containsOffset(globalOffset)) return false;
    final off = buildTextPosition(globalOffset).offset;
    final richPosition = node.getPositionByOffset(off);
    // logger.i('_updatePosition, globalOffset:$globalOffset, off:$off');
    operator.onCursor(EditingCursor(nodeIndex, richPosition));
    operator.onCursorOffset(EditingOffset(
        globalOffset, getCurrentCursorHeight(richPosition), nodeId));
    return true;
  }

  bool onDoubleTap(Offset globalOffset) {
    if (!containsOffset(globalOffset)) return false;
    final range = painter.getWordBoundary(buildTextPosition(globalOffset));
    operator.onCursor(SelectingNodeCursor(
      nodeIndex,
      node.getPositionByOffset(range.start),
      node.getPositionByOffset(range.end),
    ));
    return true;
  }

  bool onTripleTap(Offset globalOffset) {
    if (!containsOffset(globalOffset)) return false;
    operator.onCursor(
        SelectingNodeCursor(nodeIndex, node.beginPosition, node.endPosition));
    return true;
  }
}
