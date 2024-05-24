import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../editor/node/basic.dart';
import '../../../editor/node/rich_text/rich_text.dart';
import '../../../editor/extension/render_box.dart';
import '../../../editor/extension/node_context.dart';
import '../../../editor/cursor/basic.dart';
import '../../../editor/cursor/table.dart';
import '../../../editor/extension/unmodifiable.dart';
import '../../core/context.dart';
import '../../core/copier.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../../exception/editor_node.dart';
import '../../node/table/generator/common.dart';
import '../../node/table/table.dart';
import '../../node/table/table_cell.dart' as tc;
import '../../node/table/table_cell_list.dart';
import '../../shortcuts/arrows/arrows.dart';
import '../../shortcuts/arrows/single_arrow.dart';
import '../editor/shared_node_context_widget.dart';
import 'table_cell.dart';
import 'table_operator.dart';

class RichTable extends StatefulWidget {
  final NodesOperator context;
  final TableNode node;
  final NodeBuildParam param;

  const RichTable(this.context, this.node, this.param, {super.key});

  @override
  State<RichTable> createState() => _RichTableState();
}

class _RichTableState extends State<RichTable> {
  TableNode get node => widget.node;

  NodesOperator get nodeContext => widget.context;

  SingleNodeCursor? get nodeCursor => widget.param.cursor;

  ListenerCollection get listeners => nodeContext.listeners;

  int get widgetIndex => widget.param.index;

  final ValueNotifier<double?> heightNotifier = ValueNotifier(null);
  final ValueNotifier<List<double>> heightsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> operatorShowerNotifier = ValueNotifier(false);
  final ValueNotifier<_MouseState?> mouseNotifier = ValueNotifier(null);
  final key = GlobalKey();

  late ListenerCollection localListeners;

  final LayerLink layerLink = LayerLink();

  @override
  void initState() {
    updateSize();
    localListeners = listeners.copy(
      nodeListeners: {},
      nodesListeners: {},
      cursorListeners: {},
      gestureListeners: {},
      arrowDelegates: {},
    );
    listeners.addGestureListener(node.id, onGesture);
    listeners.addArrowDelegate(node.id, onArrowAccept);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RichTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldListeners = oldWidget.context.listeners;
    if (oldListeners.hashCode != listeners.hashCode) {
      oldListeners.removeGestureListener(node.id, onGesture);
      oldListeners.removeArrowDelegate(node.id, onArrowAccept);
      listeners.addGestureListener(node.id, onGesture);
      listeners.addArrowDelegate(node.id, onArrowAccept);
      logger.i(
          '${node.runtimeType} onListenerChanged:${oldListeners.hashCode},  newListener:${listeners.hashCode}');
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    listeners.removeGestureListener(node.id, onGesture);
    listeners.removeArrowDelegate(node.id, onArrowAccept);
    localListeners.dispose();
    heightNotifier.dispose();
    heightsNotifier.dispose();
    mouseNotifier.dispose();
    operatorShowerNotifier.dispose();
  }

  void onGesture(GestureState s) {
    if (s is TapGestureState) {
      onTap(s);
    } else if (s is HoverGestureState) {
      onHover(s);
    } else if (s is PanGestureState) {
      onPan(s);
    }
  }

  void onTap(TapGestureState s) {
    final box = renderBox;
    if (box == null) return;
    final heights = List.of(heightsNotifier.value);
    final widths = List.of(node.widths);
    final cellPosition = box.getCellPosition(s.globalOffset, heights, widths);
    if (cellPosition == null) return;
    final cell = node.getCell(cellPosition);
    localListeners.notifyGesture(cell.id, s);
  }

  void onHover(GestureState s) {
    final offset = s.globalOffset;
    if (!containsOffset(offset)) return;
    var p = nodeCursor;
    if (p == null) return;
    if (p is EditingCursor) return;
    p = p as SelectingNodeCursor;
    var left = p.left;
    var right = p.right;
    if (left is! TablePosition || right is! TablePosition) return;
    if (left.sameCell(right)) {
      final cell = node.getCell(left.cellPosition);
      final cursor = node.getCursorInCell(p.as<TablePosition>(), left.cellPosition);
      if (!cell.wholeSelected(cursor)) {
        localListeners.notifyGestures(s);
        return;
      }
    }
    final entryManager =
        ShareEditorContextWidget.of(context)?.context.entryManager;
    if (entryManager == null) return;
    if (entryManager.lastShowingContextType == nodeContext.runtimeType) return;
    final heights = List.of(heightsNotifier.value);
    heights.insert(0, 0);
    final widths = List.of(node.widths);
    widths.insert(0, 0);
    final box = renderBox;
    if (box == null) return;
    if (box.containsOffsetInTable(s.globalOffset, left.cellPosition,
        right.cellPosition, heights, widths)) {
      entryManager.showTextMenu(
          Overlay.of(context),
          MenuInfo(box.globalToLocal(s.globalOffset), node.id, 0, layerLink),
          nodeContext);
    }
  }

  void onPan(PanGestureState o) {
    final box = renderBox;
    if (box == null) return;
    final heights = List.of(heightsNotifier.value);
    final widths = List.of(node.widths);
    final lastCellPosition =
        box.getCellPosition(o.beginOffset, heights, widths);
    final cellPosition = box.getCellPosition(o.globalOffset, heights, widths);
    logger.i(
        'last:$lastCellPosition,  current:$cellPosition,  global:${o.globalOffset}');
    if (cellPosition == null) return;
    final cell = node.getCell(cellPosition);
    if (lastCellPosition != null) {
      if (lastCellPosition.sameCell(cellPosition)) {
        localListeners.notifyGestures(o);
        return;
      }
    }
    nodeContext.onPanUpdate(EditingCursor(
        widgetIndex, TablePosition(cellPosition, cell.endCursor)));
  }

  void onArrowAccept(AcceptArrowData d) {
    final box = renderBox;
    if (box == null) return;
    final p = d.position;
    if (p is! TablePosition) return;
    final widgetPosition = box.localToGlobal(Offset.zero);
    final type = d.type;
    final cursor = node.getCursorInCell(nodeCursor, p.cellPosition);
    switch (type) {
      case ArrowType.current:
        final extra = d.extras;
        if (extra is Offset) {
          final globalY = widgetPosition.dy;
          Offset? tapOffset;
          if (p == node.endPosition) {
            tapOffset = Offset(extra.dx, globalY + box.size.height);
          } else if (p == node.beginPosition) {
            tapOffset = Offset(extra.dx, globalY);
          }
          if (tapOffset == null) return;
          listeners.notifyGestures(TapGestureState(tapOffset));
        }
        break;
      case ArrowType.left:
      case ArrowType.up:
        if (cursor != null) {
          final ctx = buildTableCellNodeContext(
              nodeContext, p.cellPosition, node, cursor, widgetIndex);
          arrowOnLeftOrUp(type, ctx, runtimeType, cursor);
        }
        break;
      case ArrowType.right:
      case ArrowType.down:
        if (cursor != null) {
          final ctx = buildTableCellNodeContext(
              nodeContext, p.cellPosition, node, cursor, widgetIndex);
          arrowOnRightOrDown(type, ctx, runtimeType, cursor);
        }
        break;
      default:
        break;
    }
  }

  void toggleShowerNotifier(bool show) {
    if (!mounted) return;
    final v = operatorShowerNotifier.value;
    if (v == show) return;
    operatorShowerNotifier.value = show;
  }

  bool containsOffset(Offset global) =>
      renderBox?.containsOffset(global) ?? false;

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

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  @override
  Widget build(BuildContext context) {
    final widths = node.widths;
    final Map<int, FixedColumnWidth> widthsMap = buildWidthsMap(node);
    final table = node.table;
    final wholeContain = node.wholeContain(nodeCursor);
    final tableBorderWidth = 1.0;
    final operatorSize = 16.0;
    final nodeContext = ShareEditorContextWidget.of(context)!.context;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: MouseRegion(
        onHover: (d) => toggleShowerNotifier(true),
        onExit: (d) => toggleShowerNotifier(false),
        child: Stack(
          children: [
            CompositedTransformTarget(
              link: layerLink,
              child: Container(
                alignment: Alignment.topLeft,
                child: Container(
                  foregroundDecoration: wholeContain
                      ? BoxDecoration(color: Colors.blue.withOpacity(0.5))
                      : null,
                  margin: EdgeInsets.only(
                      right: operatorSize,
                      top: operatorSize,
                      bottom: operatorSize),
                  child: Table(
                    key: key,
                    columnWidths: widthsMap,
                    border: TableBorder.all(width: tableBorderWidth),
                    children: List.generate(table.length, (r) {
                      final cellList = table[r];
                      return TableRow(
                          children: List.generate(cellList.length, (c) {
                        CellPosition cp = CellPosition(r, c);
                        tc.TableCell cell = node.getCell(cp);
                        BasicCursor? cursor = wholeContain
                            ? null
                            : node.getCursorInCell(nodeCursor, cp);
                        return Stack(
                          key: ValueKey(cell.id),
                          children: [
                            RichTableCell(
                              cursor: cursor,
                              listeners: localListeners,
                              cell: cell,
                              cellPosition: cp,
                              param: widget.param,
                              context: nodeContext,
                              node: node,
                              cellId: cell.id,
                            ),
                            ValueListenableBuilder(
                                valueListenable: heightsNotifier,
                                builder: (ctx, heights, child) {
                                  final w = widths[c];
                                  if (heights.length <= r) {
                                    return Container(width: w);
                                  }
                                  final h = heights[r];
                                  if (cell.wholeSelected(cursor)) {
                                    return Container(
                                        height: h,
                                        width: w,
                                        color: Colors.blue.withOpacity(0.5));
                                  }
                                  return Container(width: w);
                                }),
                          ],
                        );
                      }));
                    }),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
                valueListenable: heightNotifier,
                builder: (ctx, height, c) {
                  if (height == null) return Container();
                  return Row(
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
                          final left = widths[index];
                          final width = delta.dx + left;
                          if (width >= 100 && width <= 800) {
                            final newWidths = widths.update(index, to(width));
                            nodeContext.onNode(
                                node.from(node.table, newWidths), widgetIndex);
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
                                  child: Container(
                                    margin: EdgeInsets.only(top: operatorSize),
                                    width: w,
                                    height: height,
                                    color: borderColor,
                                  ),
                                ),
                              );
                            }),
                      ),
                    );
                  }));
                }),
            ValueListenableBuilder(
                valueListenable: operatorShowerNotifier,
                builder: (context, v, c) {
                  if (!v) return Container();
                  return ValueListenableBuilder(
                      valueListenable: heightsNotifier,
                      builder: (ctx, heights, c) {
                        return TableOperator(
                          iconSize: operatorSize,
                          heights: heights,
                          selectedRows: node.selectedRows(nodeCursor),
                          selectedColumns: node.selectedColumns(nodeCursor),
                          onColumnDelete: (i) {
                            try {
                              final newNode = node.removeColumns(i, i + 1);
                              final cp = CellPosition(
                                  0,
                                  i >= newNode.columnCount
                                      ? newNode.columnCount - 1
                                      : i);
                              final cell = newNode.getCell(cp);
                              nodeContext.onNodeWithCursor(NodeWithCursor(
                                  newNode,
                                  TablePosition(
                                          cp,
                                          EditingCursor(
                                              0, cell.first.endPosition))
                                      .toCursor(widgetIndex)));
                            } on TableIsEmptyException {
                              final newNode = RichTextNode.from([]);
                              nodeContext.onNodeWithCursor(NodeWithCursor(
                                  newNode,
                                  newNode.beginPosition.toCursor(widgetIndex)));
                            }
                          },
                          onRowDelete: (i) {
                            try {
                              final newNode = node.removeRows(i, i + 1);
                              final cp = CellPosition(
                                  i >= newNode.rowCount
                                      ? newNode.rowCount - 1
                                      : i,
                                  0);
                              final cell = newNode.getCell(cp);
                              nodeContext.onNodeWithCursor(NodeWithCursor(
                                  newNode,
                                  TablePosition(
                                          cp,
                                          EditingCursor(
                                              0, cell.first.endPosition))
                                      .toCursor(widgetIndex)));
                              nodeContext.onNode(newNode, widgetIndex);
                            } on TableIsEmptyException {
                              final newNode = RichTextNode.from([]);
                              nodeContext.onNodeWithCursor(NodeWithCursor(
                                  newNode,
                                  newNode.beginPosition.toCursor(widgetIndex)));
                            }
                          },
                          onColumnSelected: (i) {
                            final beginPosition = CellPosition(0, i);
                            final beginCell = node.getCell(beginPosition);
                            final endPosition =
                                CellPosition(node.table.length - 1, i);
                            final endCell = node.getCell(endPosition);
                            nodeContext.onCursor(SelectingNodeCursor(
                                widgetIndex,
                                TablePosition(
                                    beginPosition, beginCell.beginCursor),
                                TablePosition(endPosition, endCell.endCursor)));
                          },
                          onRowSelected: (i) {
                            final cellList = node.table[i];
                            nodeContext.onCursor(SelectingNodeCursor(
                                widgetIndex,
                                TablePosition(CellPosition(i, 0),
                                    cellList.first.beginCursor),
                                TablePosition(
                                    CellPosition(i, cellList.length - 1),
                                    cellList.last.endCursor)));
                          },
                          onRowAdd: (i) {
                            final newNode = node.insertRows(i, [
                              TableCellList(List.generate(node.columnCount,
                                  (index) => tc.TableCell.empty()))
                            ]);
                            final cp = CellPosition(i, 0);
                            final cell = newNode.getCell(cp);
                            nodeContext.onNodeWithCursor(NodeWithCursor(
                                newNode,
                                TablePosition(cp, cell.beginCursor)
                                    .toCursor(widgetIndex)));
                          },
                          onColumnAdd: (i) {
                            final newNode = node.insertColumns(i, [
                              ColumnInfo(
                                  TableCellList(List.generate(node.rowCount,
                                      (index) => tc.TableCell.empty())),
                                  node.initWidth)
                            ]);
                            final cp = CellPosition(0, i);
                            final cell = newNode.getCell(cp);
                            nodeContext.onNodeWithCursor(NodeWithCursor(
                                newNode,
                                TablePosition(cp, cell.beginCursor)
                                    .toCursor(widgetIndex)));
                          },
                          widths: widths,
                        );
                      });
                }),
          ],
        ),
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
