import 'dart:async';
import 'dart:math';
import '../../../editor/node/rich_text/rich_text.dart';
import 'package:flutter/material.dart';

import '../../../editor/extension/cursor.dart';
import '../../command/reordering.dart';
import '../../command/replacement.dart';
import '../../core/command_invoker.dart';
import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../stateful_lifecycle_widget.dart';
import 'node_drag_target.dart';
import 'node_draggable.dart';

class AutoScrollEditorList extends StatefulWidget {
  final EditorContext editorContext;

  const AutoScrollEditorList({super.key, required this.editorContext});

  @override
  State<AutoScrollEditorList> createState() => _AutoScrollEditorListState();
}

class _AutoScrollEditorListState extends State<AutoScrollEditorList> {
  EditorContext get editorContext => widget.editorContext;

  RichEditorController get controller => editorContext.controller;

  ListenerCollection get listeners => controller.listeners;

  final tag = 'AutoScrollEditorList';
  final scrollController = ScrollController();
  final key = GlobalKey();
  final aliveDelegators = BoxDelegators();

  CursorOffset lastEditingCursorOffset = CursorOffset.zero();
  double listOffsetY = 0;
  bool isInPanGesture = false;
  Offset panUpdateOffset = Offset.zero;
  Offset panStartOffset = Offset.zero;
  late BasicCursor cursor = editorContext.cursor;
  DateTime? doubleTappedTime;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      listOffsetY = scrollController.offset;
    });
    controller.addCursorOffsetListeners(onCursorOffsetChanged);
    listeners.addCursorChangedListener(onCursorChanged);
    listeners.addDragListener(onDragListener);
    listeners.setCursorScrollCallbacks((i) async {
      await scrollTo(i, lastEditingCursorOffset.index);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    listeners.removeCursorChangedListener(onCursorChanged);
    listeners.removeDragListener(onDragListener);
    controller.removeCursorOffsetListeners(onCursorOffsetChanged);
    listeners.setCursorScrollCallbacks(null);
    super.dispose();
  }

  void onCursorOffsetChanged(CursorOffset v) {
    if (lastEditingCursorOffset == v) return;
    lastEditingCursorOffset = v;
    final box = renderBox;
    if (box == null) return;
    bool indexAlive = aliveDelegators.isIndexAlive(v.index);
    final y = v.offset.offset.dy;
    final size = box.size;
    final boxY = box.localToGlobal(Offset.zero).dy;
    double maxExtent = scrollController.position.maxScrollExtent;
    double minExtent = scrollController.position.minScrollExtent;
    if ((maxExtent - minExtent).abs() == 0) {
      if (y > size.height) {
        scrollController.animateTo(y - size.height,
            duration: Duration(milliseconds: 50), curve: Curves.linear);
      }
      return;
    }
    if (v.index == 0) {
      scrollController.animateTo(minExtent,
          duration: Duration(milliseconds: 1), curve: Curves.linear);
      return;
    } else if (v.index == controller.nodes.length - 1) {
      scrollController.animateTo(maxExtent,
          duration: Duration(milliseconds: 1), curve: Curves.linear);
      return;
    }
    if (indexAlive) {
      if (y > size.height) {
        scrollController.animateTo(
            min(maxExtent,
                listOffsetY + y - size.height - boxY + v.offset.height),
            duration: Duration(milliseconds: 1),
            curve: Curves.linear);
      } else if (y < boxY) {
        scrollController.animateTo(listOffsetY + y - boxY,
            duration: Duration(milliseconds: 1), curve: Curves.linear);
      }
    }
  }

  void onCursorChanged(BasicCursor cursor) {
    this.cursor = cursor;
    refresh();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final cursor = controller.cursor;
      if (cursor is NoneCursor) return;
      if (cursor == controller.selectAllCursor) return;
      int? index;
      logger.i(
          'onCursorChanged alive :${aliveDelegators.keys.length},  keys:${aliveDelegators.keys},  last:$lastEditingCursorOffset   ,cursor:$cursor');
      if (cursor is SingleNodeCursor) {
        index = cursor.index;
      } else if (cursor is SelectingNodesCursor) {
        index = cursor.endIndex;
      }
      if (index == null) return;
      final lastIndex = lastEditingCursorOffset.index;
      if (index == lastIndex) return;
      final box = renderBox;
      if (box == null) return;
      if (!mounted) return;
      bool indexAlive = aliveDelegators.isIndexAlive(index);
      logger.i(
          'onCursorChanged index:$index, lastIndex:$lastIndex , indexAlive:$indexAlive,  $cursor');
      if (index == 0) {
        scrollController.animateTo(scrollController.position.minScrollExtent,
            duration: Duration(milliseconds: 1), curve: Curves.linear);
        return;
      } else if (index == controller.nodes.length - 1) {
        scrollController.animateTo(scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 1), curve: Curves.linear);
        return;
      }
      scrollTo(index, lastIndex);
    });
  }

  Future scrollTo(int index, int lastIndex) async {
    bool indexAlive = aliveDelegators.isIndexAlive(index);
    if (indexAlive) return;
    final box = renderBox;
    if (box == null) return;
    await Future.doWhile(() async {
      while (!indexAlive) {
        indexAlive = aliveDelegators.isIndexAlive(index);
        bool scrollUp = lastIndex > index;
        final height = box.size.height;
        logger.i(
            '$tag, scrollTo now:$index last:$lastIndex,  map:${aliveDelegators.keys}');
        await scrollController.animateTo(
            scrollUp ? (listOffsetY - height) : (listOffsetY + height),
            duration: Duration(milliseconds: 8),
            curve: Curves.linear);
      }
      return false;
    });
  }

  void onDragListener(DragDetail d) {
    switch (d.type) {
      case DragType.start:
        isInPanGesture = true;
        break;
      case DragType.dragging:
        final box = renderBox;
        final detail = d.details;
        if (box == null || detail == null) return;
        scrollList(detail.globalPosition, detail.delta);
        break;
      case DragType.end:
        isInPanGesture = false;
        break;
    }
  }

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final nodes = controller.nodes;
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTapDown: (d) {
        logger.i('onTapDown:$d,  doubleTappedTime:$doubleTappedTime');
        editorContext.restartInput();

        ///FIXME: it's a temporary solution
        bool isTripleTap = false;
        if (doubleTappedTime != null) {
          final diffMillSecond =
              DateTime.now().difference(doubleTappedTime!).inMilliseconds;
          isTripleTap = diffMillSecond < 700;
          logger.i('diffMillSecond:$diffMillSecond');
        }
        final targetIndex = aliveDelegators.getIndex(d.globalPosition);
        if (targetIndex == null) return;
        final node = nodes[targetIndex];
        if (isTripleTap) {
          controller.notifyGesture(
              node.id, TripleTapGestureState(d.globalPosition));
        } else {
          final id = controller.notifyGesture(
              node.id, TapGestureState(d.globalPosition));
          if (id == null) {
            editorContext.execute(AddRichTextNode(RichTextNode.from([])));
          }
        }
        editorContext.removeEntry();
      },
      onDoubleTapDown: (d) {
        logger.i('onDoubleTapDown:$d');
        doubleTappedTime = DateTime.now();
        editorContext.restartInput();
        final targetIndex = aliveDelegators.getIndex(d.globalPosition);
        if (targetIndex == null) return;
        final node = nodes[targetIndex];
        controller.notifyGesture(
            node.id, DoubleTapGestureState(d.globalPosition));
        editorContext.removeEntry();
      },
      onPanStart: (d) {
        isInPanGesture = true;
        // logger.i('onPanStart:$d');
        panUpdateOffset = d.globalPosition;
        panStartOffset = d.globalPosition;
        final targetIndex = aliveDelegators.getIndex(d.globalPosition);
        if (targetIndex == null) return;
        final node = nodes[targetIndex];
        controller.notifyGesture(node.id, TapGestureState(d.globalPosition));
      },
      onPanEnd: (d) {
        isInPanGesture = false;
        panStartOffset = Offset.zero;
        // logger.i('onPanEnd:$d');
      },
      onPanDown: (d) {
        // logger.i('onPanDown:$d');
        panUpdateOffset = d.globalPosition;
        panStartOffset = d.globalPosition;
      },
      onPanUpdate: (d) {
        // logger.i('onPanUpdate:$d');

        panUpdateOffset = panUpdateOffset.translate(d.delta.dx, d.delta.dy);
        Throttle.execute(
          () {
            final targetIndex = aliveDelegators.getIndex(panUpdateOffset);
            if (targetIndex == null) return;
            logger.i('targetIndex:$targetIndex');
            final node = nodes[targetIndex];
            controller.notifyGesture(node.id, PanGestureState(d.globalPosition));
            scrollList(d.globalPosition, d.delta);
            editorContext.removeEntry();
          },
          tag: tag,
          duration: const Duration(milliseconds: 50),
        );
      },
      onPanCancel: () {
        // logger.i('onPanCancel');
        panUpdateOffset = Offset.zero;
        panStartOffset = Offset.zero;
        isInPanGesture = false;
      },
      child: MouseRegion(
        onHover: (d) {
          if (isInPanGesture) return;
          if (controller.cursor is EditingCursor) return;
          if (controller.cursor is NoneCursor) return;
          if (editorContext.entryManager.showingType != null) return;
          final targetIndex = aliveDelegators.getIndex(d.position);
          if (targetIndex == null) return;
          final node = nodes[targetIndex];
          controller.notifyGesture(node.id, HoverGestureState(d.position));
        },
        child: ListView.builder(
            key: key,
            controller: scrollController,
            padding: EdgeInsets.all(12),
            itemBuilder: (ctx, index) {
              final current = nodes[index];
              return Container(
                key: ValueKey('${current.id}-${current.runtimeType}'),
                padding: EdgeInsets.only(left: current.depth * 6, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NodeDragTarget(
                      node: current,
                      operator: editorContext,
                      onAccept: (v) => onNodeAccept(v, index),
                    ),
                    StatefulLifecycleWidget(
                      onInit: (delegate) {
                        aliveDelegators.addBoxDelegator(index, delegate);
                      },
                      onDispose: (delegate) {
                        aliveDelegators.removeBoxDelegator(index, delegate);
                      },
                      child: NodeDraggable(
                        index: index,
                        slot: RootNodeSlot(index),
                        operator: editorContext,
                        onDragUpdate: (d) {
                          final box = renderBox;
                          if (box == null) return;
                          scrollList(d.globalPosition, d.delta);
                        },
                        onDragStart: () {
                          isInPanGesture = true;
                        },
                        onDragEnd: () {
                          isInPanGesture = false;
                        },
                        child: current.build(
                            editorContext,
                            NodeBuildParam(
                              index: index,
                              cursor: cursor.getSingleNodeCursor(
                                  index, current, controller.panBeginCursor),
                            ),
                            context),
                      ),
                    ),
                    if (index == nodes.length - 1)
                      NodeDragTarget(
                        node: current,
                        operator: editorContext,
                        onAccept: (v) => onNodeAccept(v, index + 1),
                      ),
                  ],
                ),
              );
            },
            itemCount: nodes.length),
      ),
    );
  }

  void onNodeAccept(DraggableData d, int index) {
    final slot = d.slot;
    if (slot is TableCellNodeSlot) {
      editorContext.execute(MoveOutNode(MoveOut(
          slot.index, index, d.draggableNode, slot.nodeAfterDraggable)));
    } else if (slot is RootNodeSlot) {
      editorContext.execute(MoveNode(slot.index, index));
    }
  }

  void scrollList(Offset globalPosition, Offset delta) {
    const moveDistance = 20.0;
    final pixel = listOffsetY;
    if (!isInPanGesture) return;
    final box = renderBox;
    if (box == null) return;
    final listPosition = box.localToGlobal(Offset.zero);
    final listSize = box.size;
    final detectedRange = listSize.height / 5;
    final top = listPosition.dy;
    final bottom = listPosition.dy + listSize.height;
    final upRange = _VerticalRange(top, top + detectedRange);
    final bottomRange = _VerticalRange(bottom - detectedRange, bottom);
    double maxExtent = scrollController.position.maxScrollExtent;
    double minExtent = scrollController.position.minScrollExtent;
    if (upRange.isInRange(globalPosition.dy) &&
        pixel > minExtent &&
        delta.dy < 0) {
      animateTo(-moveDistance + listOffsetY);
    }

    if (bottomRange.isInRange(globalPosition.dy) &&
        pixel < maxExtent &&
        delta.dy > 0) {
      animateTo(moveDistance + listOffsetY);
    }
  }

  void animateTo(double offset) {
    scrollController.animateTo(offset,
        duration: Duration(milliseconds: 1), curve: Curves.linear);
  }
}

class _VerticalRange {
  final double top;
  final double bottom;

  _VerticalRange(this.top, this.bottom);

  bool isInRange(double y) {
    return y > top && y < bottom;
  }
}
