import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../editor/extension/node_context.dart';
import '../../../editor/cursor/basic.dart';
import '../../../editor/cursor/table.dart';
import '../../../editor/extension/unmodifiable.dart';
import '../../core/context.dart';
import '../../core/copier.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../../cursor/node_position.dart';
import '../../node/table/table.dart';
import '../../node/table/table_cell.dart' as tc;
import '../../node/table/table_cell_list.dart';
import '../../shortcuts/arrows/arrows.dart';
import '../editor/shared_node_context_widget.dart';
import 'table_cell.dart';
import 'table_operator.dart';

class RichTable extends StatefulWidget {
  final NodeContext context;
  final TableNode node;
  final NodeBuildParam param;

  const RichTable(this.context, this.node, this.param, {super.key});

  @override
  State<RichTable> createState() => _RichTableState();
}

class _RichTableState extends State<RichTable> {
  TableNode get node => widget.node;

  NodeContext get nodeContext => widget.context;

  SingleNodePosition? get position => widget.param.position;

  ListenerCollection get listeners => nodeContext.listeners;

  final ValueNotifier<double?> heightNotifier = ValueNotifier(null);
  final ValueNotifier<List<double>> heightsNotifier = ValueNotifier([]);
  final ValueNotifier<_MouseState?> mouseNotifier = ValueNotifier(null);
  final key = GlobalKey();

  final localListeners = ListenerCollection();

  int get index => widget.param.index;

  @override
  void initState() {
    updateSize();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RichTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (node.table.hashCode != oldWidget.node.table.hashCode) {
      localListeners.notifyNodes();
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    listeners.removeArrowDelegate(node.id, onArrowAccept);
    localListeners.dispose();
    heightNotifier.dispose();
    mouseNotifier.dispose();
  }

  // void onGesture(GestureState s) {
  //   switch (s.type) {
  //     case GestureType.tap:
  //       onTapped(s.globalOffset);
  //       break;
  //     case GestureType.panUpdate:
  //       onPanUpdate(s.globalOffset);
  //       break;
  //     case GestureType.hover:
  //       break;
  //   }
  // }

  Map<int, FixedColumnWidth> buildWidthsMap(TableNode n) {
    final Map<int, FixedColumnWidth> map = {};
    for (var w in node.widths) {
      map[map.length] = FixedColumnWidth(w);
    }
    return map;
  }

  void updateSize() {
    if (!mounted) return;
    final box = renderBox;
    if (box is RenderTable) {
      final h = box.size.height;
      bool needUpdateHeights = false;
      if (heightNotifier.value != h) {
        heightNotifier.value = h;
        needUpdateHeights = true;
        logger.i('updateHeight: $h');
      }
      if (needUpdateHeights) {
        List<double> heights = List.generate(box.rows, (index) => 0);
        for (var i = 0; i < box.rows; ++i) {
          final rows = box.row(i);
          double maxHeight = rows.map((e) => e.size.height).reduce(max);
          heights[i] = maxHeight;
        }
        heightsNotifier.value = heights;
        logger.i('updateHeights: $heights');
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((t) => updateSize());
  }

  void onArrowAccept(AcceptArrowData data) {}

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  @override
  Widget build(BuildContext context) {
    final widths = node.widths;
    final Map<int, FixedColumnWidth> widthsMap = buildWidthsMap(node);
    final table = node.table;
    final wholeContain = node.wholeContain(position);
    final tableBorderWidth = 1.0;
    final operatorSize = 10.0;
    final nodeContext = ShareEditorContextWidget.of(context)!.context;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Stack(
        children: [
          Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.only(
                left: operatorSize, top: operatorSize, bottom: operatorSize),
            child: Container(
              foregroundDecoration: wholeContain
                  ? BoxDecoration(color: Colors.blue.withOpacity(0.5))
                  : null,
              child: Table(
                key: key,
                columnWidths: widthsMap,
                border: TableBorder.all(width: tableBorderWidth),
                children: List.generate(table.length, (r) {
                  final cellList = table[r];
                  return TableRow(
                      children: List.generate(cellList.length, (c) {
                    final cellIndex = CellIndex(r, c);
                    final cell = cellList.getCell(c);
                    BasicCursor? cursor;
                    if (wholeContain) {
                      cursor = cell.selectAllCursor;
                    } else {
                      cursor = cell.getCursor(position, cellIndex);
                    }
                    return RichTableCell(
                      key: ValueKey(cell.id),
                      cursor: cursor,
                      listeners: localListeners,
                      cell: cell,
                      cellIndex: cellIndex,
                      param: widget.param,
                      context: nodeContext,
                      node: node,
                    );
                  }));
                }),
              ),
            ),
          ),
          ValueListenableBuilder(
              valueListenable: heightNotifier,
              builder: (ctx, height, c) {
                if (height == null) return Container();
                return Padding(
                  padding:
                      EdgeInsets.only(left: operatorSize, top: operatorSize),
                  child: Row(
                      children: List.generate(widths.length, (index) {
                    var left = widths[index];
                    final w = 5.0;
                    final transparentArea = 8.0;
                    if (index == 0) {
                      left = max(w, left - transparentArea / 2);
                    } else {
                      left = max(w, left - transparentArea);
                    }
                    return Padding(
                      padding: EdgeInsets.only(left: left),
                      child: GestureDetector(
                        onHorizontalDragStart: (e) {
                          mouseNotifier.value =
                              _MouseState(index, _MouseStatus.dragging);
                        },
                        onHorizontalDragEnd: (e) {
                          mouseNotifier.value = null;
                        },
                        onHorizontalDragCancel: () {
                          mouseNotifier.value = null;
                        },
                        onHorizontalDragUpdate: (e) {
                          final delta = e.delta;
                          logger.i('onHorizontalDragUpdate:$delta');
                          final left = widths[index];
                          final width = delta.dx + left;
                          if (width >= 100 && width <= 800) {
                            final newWidths = widths.update(index, to(width));
                            nodeContext.onNode(
                                node.from(node.table, newWidths), index);
                          }
                          mouseNotifier.value =
                              _MouseState(index, _MouseStatus.dragging);
                        },
                        child: ValueListenableBuilder(
                            valueListenable: mouseNotifier,
                            builder: (context, v, c) {
                              _MouseStatus status = _MouseStatus.idle;
                              if (v != null && v.index == index) {
                                status = v.status;
                              }
                              bool dragging = status == _MouseStatus.dragging;
                              bool idle = status == _MouseStatus.idle;
                              final borderColor =
                                  idle ? Colors.transparent : Colors.blue;
                              return MouseRegion(
                                cursor: dragging
                                    ? SystemMouseCursors.grabbing
                                    : SystemMouseCursors.grab,
                                onHover: (e) {
                                  if (dragging) return;
                                  mouseNotifier.value =
                                      _MouseState(index, _MouseStatus.hovering);
                                },
                                onExit: (e) {
                                  if (dragging) return;
                                  mouseNotifier.value = null;
                                },
                                child: SizedBox(
                                  width: transparentArea,
                                  child: Center(
                                    child: Container(
                                      width: w,
                                      height: height,
                                      color: borderColor,
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                    );
                  })),
                );
              }),
          ValueListenableBuilder(
              valueListenable: heightsNotifier,
              builder: (ctx, heights, c) {
                return Padding(
                  padding: EdgeInsets.only(top: operatorSize),
                  child: TableRowOperator(
                    heights: heights,
                    onSelect: (i) {
                      final cellList = node.table[i];
                      nodeContext.onCursor(SelectingNodeCursor(
                          index,
                          TablePosition(
                              CellIndex(i, 0), cellList.first.beginCursor),
                          TablePosition(CellIndex(i, cellList.length - 1),
                              cellList.last.endCursor)));
                    },
                    onAdd: (i) {
                      final newNode = node.insertRows(i, [
                        TableCellList(List.generate(
                            node.columnCount, (index) => tc.TableCell.empty()))
                      ]);
                      nodeContext.onNode(newNode, index);
                    },
                  ),
                );
              })
        ],
      ),
    );
  }
}

enum _MouseStatus { hovering, dragging, idle }

class _MouseState {
  final int index;
  final _MouseStatus status;

  _MouseState(this.index, this.status);
}
