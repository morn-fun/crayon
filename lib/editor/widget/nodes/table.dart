import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../editor/cursor/basic.dart';
import '../../../editor/extension/cursor.dart';
import '../../../editor/cursor/table.dart';
import '../../../editor/extension/unmodifiable.dart';
import '../../core/copier.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../../core/node_controller.dart';
import '../../cursor/node_position.dart';
import '../../cursor/table_cell.dart';
import '../../node/basic.dart';
import '../../node/rich_text/rich_text.dart';
import '../../node/table/table.dart';
import '../../node/table/table_cell.dart' as tc;
import '../../node/table/table_cell_list.dart';
import '../../shortcuts/arrows/arrows.dart';
import '../editor/shared_node_context_widget.dart';
import 'table_cell.dart';
import 'table_operator.dart';

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
  TableNode get node => widget.node;

  NodeController get controller => widget.controller;

  SingleNodePosition? get position => widget.position;

  ListenerCollection get listeners => controller.listeners;

  final ValueNotifier<double?> heightNotifier = ValueNotifier(null);
  final ValueNotifier<List<double>> heightsNotifier = ValueNotifier([]);
  final ValueNotifier<_MouseState?> mouseNotifier = ValueNotifier(null);
  final key = GlobalKey();

  final localListeners = ListenerCollection();

  @override
  void initState() {
    updateSize();
    listeners.addArrowDelegate(node.id, onArrowAccept);
    listeners.addChildListener(localListeners);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RichTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (node.hashCode != oldWidget.hashCode) {
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
    listeners.removeChildListener(localListeners);
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
    final nodeContext = ShareNodeContextWidget.of(context)!.context;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Stack(
        children: [
          Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.only(left: operatorSize, top: operatorSize, bottom: operatorSize),
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
                    final cell = cellList.getCell(c);
                    tc.CellCursorStatus status = tc.CellCursorStatus.outer;
                    if (!wholeContain) {
                      status = cell.getCursorStatus(position, r, c);
                    }
                    bool innerCell = status == tc.CellCursorStatus.inner;
                    BasicCursor? cursor;
                    if (innerCell) {
                      cursor = _fromPosition(position!);
                    }
                    final child = Container(
                      foregroundDecoration: status ==
                              tc.CellCursorStatus.current
                          ? BoxDecoration(color: Colors.blue.withOpacity(0.5))
                          : null,
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(cell.length, (i) {
                          final innerNode = cell.getNode(i);
                          SingleNodePosition? innerPosition;
                          if (cursor != null) {
                            innerPosition =
                                cursor.getSingleNodePosition(i, innerNode);
                          }
                          return Container(
                            padding: EdgeInsets.only(
                                left: innerNode.depth * 12, right: 4),
                            child: innerNode.build(
                                controller.copy(
                                  listeners: localListeners,
                                  onEditingPosition: (p) {
                                    final realPosition = TablePosition(
                                        r, c, TableCellPosition(i, p));
                                    controller.onEditingPosition
                                        .call(realPosition);
                                  },
                                  onPanUpdatePosition: (p) {
                                    final realPosition = TablePosition(
                                        r, c, TableCellPosition(i, p));
                                    controller.onPanUpdatePosition
                                        .call(realPosition);
                                  },
                                  cursorGenerator: (p) {
                                    SingleNodePosition<NodePosition> position =
                                        buildTablePosition(p, r, c, i);
                                    return controller.cursorGenerator
                                        .call(position);
                                  },
                                  nodeGetter: (i) => cell.getNode(i),
                                  onNodeChanged: (n) {
                                    final newNode = node.updateCell(
                                        r, c, to(cell.update(i, to(n))));
                                    controller.onNodeChanged.call(newNode);
                                  },
                                ),
                                innerPosition,
                                i),
                          );
                        }),
                      ),
                    );
                    return Container(
                      child: TableCell(
                        child: innerCell
                            ? RichTableCell(
                                id: node.getCell(r, c).getId(node.id, r, c),
                                cursorGetter: () => _fromPosition(position!),
                                listeners: localListeners,
                                onReplace: (v) {
                                  final newCell = node.getCell(r, c).replaceMore(
                                      v.begin, v.end, v.newNodes);
                                  controller.notifyNodeWithPosition(
                                      NodeWithPosition(
                                          node.updateCell(r, c, (t) => newCell),
                                          TablePosition(
                                                  r, c, TableCellPosition.empty())
                                              .fromCursor(v.cursor)));
                                },
                                onUpdate: (v) {
                                  final newCell =
                                  node.getCell(r, c).update(v.index, (n) => v.node);
                                  controller.notifyNodeWithPosition(
                                      NodeWithPosition(
                                          node.updateCell(r, c, (t) => newCell),
                                          TablePosition(
                                                  r, c, TableCellPosition.empty())
                                              .fromCursor(v.cursor)));
                                },
                                onCursor: (newCursor) {
                                  final np = TablePosition(
                                          r, c, TableCellPosition.empty())
                                      .fromCursor(newCursor);
                                  if (np is EditingPosition) {
                                    controller.notifyEditingPosition(np.position);
                                  } else if (np is SelectingPosition) {
                                    controller.notifySelectingPosition(np);
                                  }
                                },
                                cellGetter: () => node.getCell(r, c),
                                nodeContext: nodeContext,
                                child: child)
                            : child,
                      ),
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
                            controller
                                .updateNode(node.from(node.table, newWidths));
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
                      controller.notifySelectingPosition(SelectingPosition(
                          TablePosition(i, 0, cellList.first.beginPosition),
                          TablePosition(i, cellList.length - 1,
                              cellList.last.endPosition)));
                    },
                    onAdd: (i) {
                      final newNode = node.insertRows(i, [
                        TableCellList(List.generate(node.columnCount,
                            (index) => tc.TableCell([RichTextNode.from([])])))
                      ]);
                      controller.updateNode(newNode);
                    },
                  ),
                );
              })
        ],
      ),
    );
  }

  SingleNodePosition<NodePosition> buildTablePosition(
      SingleNodePosition<NodePosition> p, int r, int c, int i) {
    late SingleNodePosition position;
    if (p is EditingPosition) {
      position = EditingPosition(
          TablePosition(r, c, TableCellPosition(i, p.position)));
    } else if (p is SelectingPosition) {
      position = SelectingPosition(
          TablePosition(r, c, TableCellPosition(i, p.begin)),
          TablePosition(r, c, TableCellPosition(i, p.end)));
    }
    return position;
  }
}

enum _MouseStatus { hovering, dragging, idle }

class _MouseState {
  final int index;
  final _MouseStatus status;

  _MouseState(this.index, this.status);
}

BasicCursor _fromPosition(SingleNodePosition position) {
  if (position is EditingPosition) {
    final p = position.position as TablePosition;
    return EditingCursor(p.index, p.position);
  }
  position = position as SelectingPosition;
  final left = position.left as TablePosition;
  final right = position.right as TablePosition;
  if (left.index == right.index) {
    return SelectingNodeCursor(left.index, left.position, right.position);
  }
  return SelectingNodesCursor(IndexWithPosition(left.index, left.position),
      IndexWithPosition(right.index, right.position));
}
