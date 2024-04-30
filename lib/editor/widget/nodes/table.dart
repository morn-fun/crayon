import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/logger.dart';
import '../../core/node_controller.dart';
import '../../cursor/node_position.dart';
import '../../node/table/table.dart';

class RichTable extends StatefulWidget {
  final NodeController controller;
  final TableNode node;
  final SingleNodePosition? position;

  const RichTable(
      {super.key, required this.controller, required this.node, this.position});

  @override
  State<RichTable> createState() => _RichTableState();
}

class _RichTableState extends State<RichTable> {
  final Map<int, FixedColumnWidth> widthMap = {
    0: FixedColumnWidth(200),
    1: FixedColumnWidth(200),
    2: FixedColumnWidth(200),
  };
  final ValueNotifier<double?> heightNotifier = ValueNotifier(null);

  final key = GlobalKey();
  bool dragging = false;

  @override
  void initState() {
    updateHeight();
    super.initState();
  }

  void updateHeight() {
    if (!mounted) return;
    final h = renderBox?.size.height;
    if (heightNotifier.value != h) {
      heightNotifier.value = h;
      logger.i('updateHeight: $h');
    }
    WidgetsBinding.instance.addPostFrameCallback((t) => updateHeight());
  }

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          key: key,
          alignment: Alignment.topLeft,
          child: Table(
            columnWidths: widthMap,
            children: List.generate(3, (i) {
              return TableRow(
                  children: List.generate(3, (index) => test(0, index)));
            }),
          ),
        ),
        ValueListenableBuilder(
            valueListenable: heightNotifier,
            builder: (ctx, v, c) {
              if (v == null) return Container();
              final keys = widthMap.keys.toList();
              return Row(
                  children: List.generate(widthMap.length, (index) {
                var left = widthMap[keys[index]]!.value;
                final w = 2.0;
                left = max(w, left - 2);
                return Padding(
                  padding: EdgeInsets.only(left: left),
                  child: GestureDetector(
                    onHorizontalDragStart: (e) {
                      dragging = true;
                      refresh();
                    },
                    onHorizontalDragEnd: (e) {
                      dragging = false;
                      refresh();
                    },
                    onHorizontalDragCancel: () {
                      dragging = false;
                      refresh();
                    },
                    onHorizontalDragUpdate: (e) {
                      final delta = e.delta;
                      logger.i('onHorizontalDragUpdate:$delta');
                      final left = widthMap[keys[index]]!.value;
                      final width = delta.dx + left;
                      if (width >= 100 && width <= 800) {
                        widthMap[keys[index]] = FixedColumnWidth(width);
                        refresh();
                      }
                    },
                    child: MouseRegion(
                      cursor: dragging
                          ? SystemMouseCursors.grabbing
                          : SystemMouseCursors.grab,
                      child: Container(
                        width: w,
                        height: v,
                        color: Colors.yellow,
                      ),
                    ),
                  ),
                );
              }));
            })
      ],
    );
  }

  Widget test(int row, int column) {
    var left = widthMap[column]!.value;
    return SizedBox(
      width: left,
      child: Container(
        width: left,
        height: 100,
        color: Colors.blueAccent,
        child: Text('$row---$column'),
      ),
    );
  }
}
