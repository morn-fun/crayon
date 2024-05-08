import 'dart:math';

import 'package:flutter/material.dart' hide TableCell;

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
import '../../node/table/table.dart';
import '../../node/table/table_cell.dart';
import '../../shortcuts/arrows/arrows.dart';

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
  final ValueNotifier<_MouseState?> mouseNotifier = ValueNotifier(null);
  final key = GlobalKey();

  @override
  void initState() {
    updateHeight();
    listeners.addArrowDelegate(node.id, onArrowAccept);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RichTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (position != oldWidget.position) {
      refresh();
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    listeners.removeArrowDelegate(node.id, onArrowAccept);
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

  void updateHeight() {
    if (!mounted) return;
    final h = renderBox?.size.height;
    if (heightNotifier.value != h) {
      heightNotifier.value = h;
      logger.i('updateHeight: $h');
    }
    WidgetsBinding.instance.addPostFrameCallback((t) => updateHeight());
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
    final wholeContain = _wholeContain(position, node);
    final tableBorderWidth = 1.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Stack(
        children: [
          Container(
            key: key,
            alignment: Alignment.topLeft,
            child: Container(
              foregroundDecoration: wholeContain
                  ? BoxDecoration(color: Colors.blue.withOpacity(0.5))
                  : null,
              child: Table(
                columnWidths: widthsMap,
                border: TableBorder.all(width: tableBorderWidth),
                children: List.generate(table.length, (r) {
                  final cellList = table[r];
                  return TableRow(
                      children: List.generate(cellList.length, (c) {
                    final cell = cellList.getCell(c);
                    _ContainStatus status = _ContainStatus.outer;
                    if (!wholeContain) {
                      status = _containCell(position, r, c, cell);
                    }
                    return Container(
                      foregroundDecoration: status == _ContainStatus.current
                          ? BoxDecoration(color: Colors.blue.withOpacity(0.5))
                          : null,
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(cell.length, (i) {
                          final innerNode = cell.getNode(i);
                          SingleNodePosition? innerPosition;
                          if (status == _ContainStatus.inner) {
                            final cursor = _fromPosition(position!);
                            innerPosition =
                                cursor.getSingleNodePosition(i, innerNode);
                          }
                          return Container(
                            padding: EdgeInsets.only(
                                left: innerNode.depth * 12, right: 4),
                            child: innerNode.build(
                                controller.copy(
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
                                    late SingleNodePosition position;
                                    if (p is EditingPosition) {
                                      position = EditingPosition(TablePosition(
                                          r,
                                          c,
                                          TableCellPosition(i, p.position)));
                                    } else if (p is SelectingPosition) {
                                      position = SelectingPosition(
                                          TablePosition(r, c,
                                              TableCellPosition(i, p.begin)),
                                          TablePosition(r, c,
                                              TableCellPosition(i, p.end)));
                                    }
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
                  }));
                }),
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
                  if(index == 0){
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
                }));
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

bool _wholeContain(SingleNodePosition? position, TableNode node) {
  if (position is! SelectingPosition) return false;
  var left = position.left;
  var right = position.right;
  if (left is! TablePosition && right is! TablePosition) {
    return false;
  }
  left = left as TablePosition;
  right = right as TablePosition;
  return left == node.beginPosition && right == node.endPosition;
}

_ContainStatus _containCell(
    SingleNodePosition? position, int row, int column, TableCell cell) {
  final p = position;
  if (p == null) return _ContainStatus.outer;
  if (p is EditingPosition) {
    var pTable = p.position;
    if (pTable is! TablePosition) return _ContainStatus.outer;
    if (pTable.column == column && pTable.row == row) {
      return _ContainStatus.inner;
    }
    return _ContainStatus.outer;
  }
  if (p is SelectingPosition) {
    var left = p.left;
    var right = p.right;
    if (left is! TablePosition && right is! TablePosition) {
      return _ContainStatus.outer;
    }
    left = left as TablePosition;
    right = right as TablePosition;
    if (left.inSameCell(right) && left.column == column && left.row == row) {
      bool wholeSelected =
          cell.wholeSelected(left.cellPosition, right.cellPosition);
      return wholeSelected ? _ContainStatus.current : _ContainStatus.inner;
    }
    bool containsSelf = cell.containSelf(left, right, row, column);
    return containsSelf ? _ContainStatus.current : _ContainStatus.outer;
  }
  return _ContainStatus.outer;
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

enum _ContainStatus { inner, current, outer }
