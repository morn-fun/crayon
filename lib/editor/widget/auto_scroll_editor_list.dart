import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../core/command_invoker.dart';
import '../core/context.dart';
import '../core/controller.dart';
import '../core/listener_collection.dart';
import '../core/logger.dart';
import '../cursor/basic_cursor.dart';
import 'stateful_lifecycle_widget.dart';

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
  final aliveIndexSet = <int>{};

  CursorOffset lastEditingCursorOffset = CursorOffset(0, 0, 0);
  double listOffsetY = 0;
  double maxExtent = 0;
  double minExtent = 0;
  bool isDealingWithOffset = false;
  bool isInPanGesture = false;
  final tag = 'AutoScrollEditorList';

  @override
  void initState() {
    super.initState();
    scrollOffsetSubscription = scrollOffsetListener.changes.listen((event) {
      listOffsetY += event;
      // logger.i('y:$listOffsetY, max:$maxExtent, min:$minExtent, event:$event');
    });
    listeners.addEditingCursorOffsetListener(onCursorOffsetChanged);
    listeners.addCursorChangedListener(onCursorChanged);
  }

  @override
  void dispose() {
    listeners.removeEditingCursorOffsetListener(onCursorOffsetChanged);
    listeners.removeCursorChangedListener(onCursorChanged);
    scrollOffsetSubscription.cancel();
    super.dispose();
  }

  void onCursorOffsetChanged(CursorOffset v) {
    if(isDealingWithOffset) return;
    if (lastEditingCursorOffset == v) return;
    final cursor = controller.cursor;
    if (cursor is! EditingCursor) return;
    lastEditingCursorOffset = v;
    final box = renderBox;
    if (box == null) return;
    isDealingWithOffset = true;
    final size = box.size;
    final offset = box.localToGlobal(Offset.zero);
    final top = offset.dy;
    final bottom = size.height + top;
    final globalY = v.globalY;
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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final cursor = controller.cursor;
      if (cursor is! EditingCursor) return;
      if (isDealingWithOffset) return;
      final index = cursor.index;
      final lastIndex = lastEditingCursorOffset.index;
      if (index == lastIndex) return;
      final box = renderBox;
      if (box == null) return;
      bool contains = aliveIndexSet.contains(cursor.index);
      if (contains) return;
      if (!mounted) return;
      logger.i(
          'onCursorChanged index:$index, lastIndex:$lastIndex  $cursor');
      itemScrollController.jumpTo(index: cursor.index, alignment: index > lastIndex ? 1 : 0);
    });
  }

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  @override
  Widget build(BuildContext context) {
    final nodes = controller.nodes;
    bool needTapDownWhilePanGesture = false;
    Offset panOffset = Offset.zero;
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.translucent,
      onTapDown: (d) {
        // logger.i('onTapDown:$d');
        controller
            .notifyGesture(GestureState(GestureType.tap, d.globalPosition));
      },
      onPanStart: (d) {
        isInPanGesture = true;
        // logger.i('onPanStart:$d');
        panOffset = d.globalPosition;
      },
      onPanEnd: (d) {
        isInPanGesture = false;
        // logger.i('onPanEnd:$d');
        controller
            .notifyGesture(GestureState(GestureType.panUpdate, panOffset));
      },
      onPanDown: (d) {
        // logger.i('onPanDown:$d');
        panOffset = d.globalPosition;
        needTapDownWhilePanGesture = true;
      },
      onPanUpdate: (d) {
        // logger.i('onPanUpdate:$d');
        if (needTapDownWhilePanGesture) {
          controller.notifyGesture(GestureState(GestureType.tap, panOffset));
          needTapDownWhilePanGesture = false;
        }
        panOffset = panOffset.translate(d.delta.dx, d.delta.dy);
        Throttle.execute(
          () {
            controller.notifyGesture(
                GestureState(GestureType.panUpdate, d.globalPosition));
            scrollList(d.globalPosition);
          },
          tag: tag,
          duration: const Duration(milliseconds: 50),
        );
      },
      onPanCancel: () {
        // logger.i('onPanCancel');
        panOffset = Offset.zero;
        needTapDownWhilePanGesture = false;
        isInPanGesture = false;
      },
      child: MouseRegion(
        onHover: (d) {
          if (isInPanGesture) return;
          if (controller.cursor is EditingCursor) return;
          controller.notifyGesture(GestureState(GestureType.hover, d.position));
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
                  key: ValueKey(current.id),
                  padding: EdgeInsets.only(left: current.depth * 12),
                  child: StatefulLifecycleWidget(
                    onInit: () => aliveIndexSet.add(index),
                    onDispose: () => aliveIndexSet.remove(index),
                    child: current.build(editorContext, index),
                  ),
                );
              },
              itemCount: nodes.length),
        ),
      ),
    );
  }

  void scrollList(Offset globalPosition) {
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
    if (upRange.isInRange(globalPosition.dy) && pixel > minExtent) {
      animateTo(-moveDistance);
    }

    if (bottomRange.isInRange(globalPosition.dy) && pixel < maxExtent) {
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
