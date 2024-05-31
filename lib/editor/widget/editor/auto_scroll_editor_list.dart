import 'dart:async';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../editor/extension/cursor.dart';
import '../../command/replacement.dart';
import '../../core/command_invoker.dart';
import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../stateful_lifecycle_widget.dart';

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

  final itemScrollController = ItemScrollController();
  final scrollOffsetController = ScrollOffsetController();
  final scrollOffsetListener = ScrollOffsetListener.create();
  late StreamSubscription<double> scrollOffsetSubscription;
  final key = GlobalKey();
  final aliveIndexMap = <int, Set<String>>{};

  CursorOffset lastEditingCursorOffset = CursorOffset.zero();
  double listOffsetY = 0;
  double maxExtent = 0;
  double minExtent = 0;
  bool isDealingWithOffset = false;
  bool isInPanGesture = false;
  Offset panOffset = Offset.zero;
  Offset panStartOffset = Offset.zero;
  final tag = 'AutoScrollEditorList';
  late BasicCursor cursor = editorContext.cursor;
  DateTime? doubleTappedTime;


  @override
  void initState() {
    super.initState();
    scrollOffsetSubscription = scrollOffsetListener.changes.listen((event) {
      listOffsetY += event;
      // logger.i('y:$listOffsetY, max:$maxExtent, min:$minExtent, event:$event');
    });
    controller.addCursorOffsetListeners(onCursorOffsetChanged);
    listeners.addCursorChangedListener(onCursorChanged);
  }

  @override
  void dispose() {
    listeners.removeCursorChangedListener(onCursorChanged);
    controller.removeCursorOffsetListeners(onCursorOffsetChanged);
    scrollOffsetSubscription.cancel();
    super.dispose();
  }

  void onCursorOffsetChanged(CursorOffset v) {
    if (isDealingWithOffset) return;
    if (lastEditingCursorOffset == v) return;
    final cursor = controller.cursor;
    if (cursor is! EditingCursor) return;
    logger
        .i('onCursorOffsetChanged last:$lastEditingCursorOffset,  current:$v');
    lastEditingCursorOffset = v;
    final box = renderBox;
    if (box == null) return;
    isDealingWithOffset = true;
    final size = box.size;
    final offset = box.localToGlobal(Offset.zero);
    final top = offset.dy;
    final bottom = size.height + top;
    final globalY = v.y;
    if (globalY + 18 > bottom) {
      logger.i(
          'onCursorOffsetChanged down, v:$v, globalY:$globalY, top:$top, bottom:$bottom');
      scrollOffsetController.animateScroll(

          ///TODO:what is 18?
          offset: (globalY - bottom) + 18,
          duration: Duration(milliseconds: 1),
          curve: Curves.linear);
    } else if (globalY < top) {
      logger.i(
          'onCursorOffsetChanged up, v:$v, globalY:$globalY, top:$top, bottom:$bottom');
      scrollOffsetController.animateScroll(
          offset: -(top - globalY),
          duration: Duration(milliseconds: 1),
          curve: Curves.linear);
    }
    isDealingWithOffset = false;
  }

  void onCursorChanged(BasicCursor cursor) {
    this.cursor = cursor;
    refresh();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final cursor = controller.cursor;
      // logger.i(
      //     'onCursorChanged alive :${aliveIndexMap.length},  dealing:$isDealingWithOffset,  last:$lastEditingCursorOffset   ,cursor:$cursor');
      if (cursor is! EditingCursor) return;
      if (isDealingWithOffset) return;
      final index = cursor.index;
      final lastIndex = lastEditingCursorOffset.index;
      if (index == lastIndex) return;
      final box = renderBox;
      if (box == null) return;
      if (!mounted) return;
      bool contains = isIndexAlive(cursor.index);
      if (contains) return;
      logger.i('onCursorChanged index:$index, lastIndex:$lastIndex  $cursor');
      itemScrollController.jumpTo(index: cursor.index, alignment: 0);
    });
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
      key: key,
      behavior: HitTestBehavior.deferToChild,
      onTapDown: (d) {
        logger.i('onTapDown:$d,  doubleTappedTime:$doubleTappedTime');
        editorContext.restartInput();
        ///FIXME: it's a temporary solution
        bool isTripleTap = false;
        if(doubleTappedTime != null){
          final diffMillSecond = DateTime.now().difference(doubleTappedTime!).inMilliseconds;
          isTripleTap = diffMillSecond < 700;
          logger.i('diffMillSecond:$diffMillSecond');
        }
        if(isTripleTap){
          controller.notifyGesture(TripleTapGestureState(d.globalPosition));
        } else {
          final id = controller.notifyGesture(TapGestureState(d.globalPosition));
          if (id == null) {
            editorContext.execute(AddRichTextNode(RichTextNode.from([])));
          }
        }
        editorContext.removeEntry();
      },
      onDoubleTapDown: (d){
        logger.i('onDoubleTapDown:$d');
        doubleTappedTime = DateTime.now();
        editorContext.restartInput();
        controller.notifyGesture(DoubleTapGestureState(d.globalPosition));
        editorContext.removeEntry();
      },
      onPanStart: (d) {
        isInPanGesture = true;
        // logger.i('onPanStart:$d');
        panOffset = d.globalPosition;
        panStartOffset = d.globalPosition;
        controller.notifyGesture(TapGestureState(d.globalPosition));
      },
      onPanEnd: (d) {
        isInPanGesture = false;
        panStartOffset = Offset.zero;
        // logger.i('onPanEnd:$d');
      },
      onPanDown: (d) {
        // logger.i('onPanDown:$d');
        panOffset = d.globalPosition;
        panStartOffset = d.globalPosition;
      },
      onPanUpdate: (d) {
        // logger.i('onPanUpdate:$d');

        panOffset = panOffset.translate(d.delta.dx, d.delta.dy);
        Throttle.execute(
          () {
            controller
                .notifyGesture(PanGestureState(panOffset));
            scrollList(d.globalPosition, d.delta);
            editorContext.removeEntry();
          },
          tag: tag,
          duration: const Duration(milliseconds: 50),
        );
      },
      onPanCancel: () {
        // logger.i('onPanCancel');
        panOffset = Offset.zero;
        panStartOffset = Offset.zero;
        isInPanGesture = false;
      },
      child: MouseRegion(
        onHover: (d) {
          if (isInPanGesture) return;
          if (controller.cursor is EditingCursor) return;
          controller.notifyGesture(HoverGestureState(d.position));
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            maxExtent = notification.metrics.maxScrollExtent;
            minExtent = notification.metrics.minScrollExtent;
            return false;
          },
          child: ScrollablePositionedList.builder(
              padding: EdgeInsets.all(12),
              itemScrollController: itemScrollController,
              scrollOffsetListener: scrollOffsetListener,
              scrollOffsetController: scrollOffsetController,
              initialAlignment: 0,
              itemBuilder: (ctx, index) {
                final current = nodes[index];
                return Container(
                  key: ValueKey('${current.id}-${current.runtimeType}'),
                  padding: EdgeInsets.only(left: current.depth * 12, right: 4),
                  child: StatefulLifecycleWidget(
                    onInit: () {
                      addIndex(index, current.id);
                      // logger.i(
                      //     'add $index, id:${current.id},  set: ${aliveIndexMap.keys}');
                    },
                    onDispose: () {
                      removeIndex(index, current.id);
                      // logger.i(
                      //     'remove $index, id:${current.id},  set: ${aliveIndexMap.keys}');
                    },
                    child: current.build(
                        editorContext,
                        NodeBuildParam(
                          index: index,
                          cursor: cursor.getSingleNodeCursor(index, current, controller.panBeginCursor),
                        ),
                        context),
                  ),
                );
              },
              itemCount: nodes.length),
        ),
      ),
    );
  }

  void addIndex(int index, String id) {
    final set = aliveIndexMap[index] ?? {};
    set.add(id);
    aliveIndexMap[index] = set;
  }

  void removeIndex(int index, String id) {
    final set = aliveIndexMap[index] ?? {};
    set.remove(id);
    if (set.isEmpty) {
      aliveIndexMap.remove(index);
    } else {
      aliveIndexMap[index] = set;
    }
  }

  bool isIndexAlive(int index) => aliveIndexMap[index] != null;

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
    if (upRange.isInRange(globalPosition.dy) &&
        pixel > minExtent &&
        delta.dy < 0) {
      animateTo(-moveDistance);
    }

    if (bottomRange.isInRange(globalPosition.dy) &&
        pixel < maxExtent &&
        delta.dy > 0) {
      animateTo(moveDistance);
    }
  }

  void animateTo(double offset) {
    scrollOffsetController.animateScroll(
        offset: offset,
        duration: Duration(milliseconds: 1),
        curve: Curves.linear);
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
