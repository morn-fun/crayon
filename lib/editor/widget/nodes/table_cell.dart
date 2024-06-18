import 'package:flutter/material.dart';
import '../../../../editor/core/context.dart';
import '../../../../editor/core/listener_collection.dart';
import '../../../../editor/cursor/basic.dart';
import '../../../../editor/extension/cursor.dart';
import '../../core/logger.dart';
import '../../cursor/table.dart';
import '../../exception/editor_node.dart';
import '../../node/table/generator/common.dart';
import '../../node/table/table.dart';
import '../../node/table/table_cell.dart' as tc;
import '../../shortcuts/arrows/arrows.dart';
import '../../shortcuts/arrows/line_arrow.dart';
import '../../shortcuts/arrows/selection_arrow.dart';
import '../../shortcuts/arrows/selection_word_arrow.dart';
import '../../shortcuts/arrows/single_arrow.dart';
import '../../shortcuts/arrows/word_arrow.dart';
import '../editor/node_drag_target.dart';
import '../editor/node_draggable.dart';

class RichTableCell extends StatefulWidget {
  final tc.TableCell cell;
  final TableNode node;
  final CellPosition cellPosition;
  final NodeBuildParam param;
  final BasicCursor? cursor;
  final ListenerCollection listeners;
  final NodesOperator operator;
  final String cellId;

  const RichTableCell({
    super.key,
    required this.cell,
    required this.cellId,
    required this.node,
    required this.cellPosition,
    required this.operator,
    required this.param,
    required this.cursor,
    required this.listeners,
  });

  @override
  State<RichTableCell> createState() => _RichTableCellState();
}

class _RichTableCellState extends State<RichTableCell> {
  NodesOperator get operator => widget.operator;

  ListenerCollection get listeners => widget.listeners;

  tc.TableCell get cell => widget.cell;

  BasicCursor? get cursor => widget.cursor;

  TableNode get node => widget.node;

  CellPosition get cellPosition => widget.cellPosition;

  SingleNodeCursor? get nodeCursor => widget.param.cursor;

  int get widgetIndex => widget.param.index;

  String get cellId => widget.cellId;

  late TableCellNodeContext cellContext;

  late ListenerCollection localListeners;

  @override
  void initState() {
    logger.i('$runtimeType $cellId  init');
    localListeners = listeners.copy(
        nodeListeners: {},
        nodesListeners: {},
        gestureListeners: {},
        arrowDelegates: {});
    listeners.addGestureListener(cellId, onGesture);
    listeners.addArrowDelegate(cellId, onArrowAccept);
    operator.listeners.addListener(cellId, localListeners);
    super.initState();
  }

  bool onGesture(GestureState s) => localListeners.notifyGestures(s) != null;

  void onArrowAccept(AcceptArrowData d) {
    final type = d.type;
    final cursor = node.getCursorInCell(nodeCursor, cellPosition);
    switch (type) {
      case ArrowType.left:
      case ArrowType.up:
      case ArrowType.right:
      case ArrowType.down:
        if (cursor == null) {
          throw NodeUnsupportedException(
              node.runtimeType, 'onArrowAccept $type without cursor', d);
        }
        final opt = buildTableCellNodeContext(
            operator, cellPosition, node, cursor, widgetIndex);
        try {
          onArrow(opt, cursor, type);
        } on ArrowLeftBeginException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.lastInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).endCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrow(newOpt, newCursor, ArrowType.current);
        } on ArrowUpTopException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.lastInVertical(node, e.offset);
          final newCursor = node.getCell(newCellPosition).endCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrow(newOpt, newCursor, ArrowType.current);
        } on ArrowRightEndException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.nextInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).beginCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrow(newOpt, newCursor, ArrowType.current);
        } on ArrowDownBottomException catch (e) {
          logger.i('onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.nextInVertical(node, e.offset);
          final newCursor = node.getCell(newCellPosition).beginCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrow(newOpt, newCursor, ArrowType.current);
        }

      case ArrowType.selectionLeft:
      case ArrowType.selectionUp:
      case ArrowType.selectionRight:
      case ArrowType.selectionDown:
        if (cursor == null) {
          throw NodeUnsupportedException(
              node.runtimeType, 'onArrowAccept $type without cursor', d);
        }
        final opt = buildTableCellNodeContext(
            operator, cellPosition, node, cursor, widgetIndex);
        try {
          onArrowSelection(opt, cursor, type);
        } on ArrowLeftBeginException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          if (cellPosition.column == 0) throw ArrowLeftBeginException(this);
          final newCellPosition = cellPosition.lastInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).endCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrowSelection(newOpt, newCursor, ArrowType.selectionCurrent);
        } on ArrowUpTopException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          if (cellPosition.row == 0) {
            throw ArrowUpTopException(this, d.extras ?? Offset.zero);
          }
          final newCellPosition = cellPosition.lastInVertical(node, e.offset);
          final newCursor = node.getCell(newCellPosition).endCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrowSelection(newOpt, newCursor, ArrowType.selectionCurrent);
        } on ArrowRightEndException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          if (cellPosition.column == node.columnCount - 1) {
            throw ArrowRightEndException(this);
          }
          final newCellPosition = cellPosition.nextInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).beginCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrowSelection(newOpt, newCursor, ArrowType.selectionCurrent);
        } on ArrowDownBottomException catch (e) {
          logger.i('onArrowAccept of ${node.runtimeType} error: ${e.message}');
          if (cellPosition.row == node.rowCount - 1) {
            throw ArrowDownBottomException(this, d.extras ?? Offset.zero);
          }
          final newCellPosition = cellPosition.nextInVertical(node, e.offset);
          final newCursor = node.getCell(newCellPosition).beginCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrowSelection(newOpt, newCursor, ArrowType.selectionCurrent);
        }
        break;
      case ArrowType.selectionWordLast:
      case ArrowType.selectionWordNext:
        if (cursor == null) {
          throw NodeUnsupportedException(
              node.runtimeType, 'onArrowAccept $type without cursor', d);
        }
        final opt = buildTableCellNodeContext(
            operator, cellPosition, node, cursor, widgetIndex);
        try {
          onArrowWordSelection(opt, cursor, type);
        } on ArrowLeftBeginException catch (e) {
          logger.i(
              'Table $type onArrowWordSelection of ${node.runtimeType} error: ${e.message}');
          if (cellPosition.column == 0) throw ArrowLeftBeginException(this);
          final newCellPosition = cellPosition.lastInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).endCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrowWordSelection(newOpt, newCursor, ArrowType.selectionCurrent);
        } on ArrowRightEndException catch (e) {
          logger.i(
              'Table $type onArrowWordSelection of ${node.runtimeType} error: ${e.message}');
          if (cellPosition.column == node.columnCount - 1) {
            throw ArrowRightEndException(this);
          }
          final newCellPosition = cellPosition.nextInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).beginCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrowWordSelection(newOpt, newCursor, ArrowType.selectionCurrent);
        }
        break;
      case ArrowType.wordLast:
      case ArrowType.wordNext:
        if (cursor == null) {
          throw NodeUnsupportedException(
              node.runtimeType, 'onArrowAccept $type without cursor', d);
        }
        final opt = buildTableCellNodeContext(
            operator, cellPosition, node, cursor, widgetIndex);
        try {
          onArrowWord(opt, cursor, type);
        } on ArrowLeftBeginException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.lastInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).endCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrow(newOpt, newCursor, ArrowType.current);
        } on ArrowRightEndException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.nextInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).beginCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          onArrow(newOpt, newCursor, ArrowType.current);
        }
        break;
      case ArrowType.lineBegin:
      case ArrowType.lineEnd:
        if (cursor == null) return;
        final opt = buildTableCellNodeContext(
            operator, cellPosition, node, cursor, widgetIndex);
        arrowOnLine(opt, cursor, type);
        break;
      default:
        break;
    }
  }

  @override
  void didUpdateWidget(covariant RichTableCell oldWidget) {
    final oldListeners = oldWidget.listeners;
    final oldId = oldWidget.cellId;
    if (oldId != cellId || oldListeners.hashCode != listeners.hashCode) {
      logger.i('$runtimeType,  didUpdateWidget oldId:$oldId, id:$cellId');
      oldListeners.removeGestureListener(oldId, onGesture);
      oldListeners.removeArrowDelegate(oldId, onArrowAccept);
      listeners.addGestureListener(cellId, onGesture);
      listeners.addArrowDelegate(cellId, onArrowAccept);
      operator.listeners.removeListener(oldId, localListeners);
      operator.listeners.addListener(cellId, localListeners);
      logger.i(
          'TableCell onListenerChanged:${oldListeners.hashCode},  newListener:${listeners.hashCode}');
    }
    if (cell.hashCode != oldWidget.cell.hashCode) {
      localListeners.notifyNodes(cell.nodes);
      for (var n in cell.nodes) {
        localListeners.notifyNode(n);
      }
    }
    if (cursor != oldWidget.cursor) {
      localListeners.notifyCursor(cursor ?? NoneCursor());
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    operator.listeners.removeListener(cellId, localListeners);
    localListeners.dispose();
    logger.i('$cellId  dispose');
    listeners.removeGestureListener(cellId, onGesture);
    listeners.removeArrowDelegate(cellId, onArrowAccept);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool wholeSelected = cell.wholeSelected(cursor);
    final listeners = operator.listeners;
    late EditingCursor lastCursor;
    final c = cursor;
    if (c is EditingCursor) lastCursor = c;
    if (c is SelectingNodeCursor) lastCursor = c.beginCursor;
    if (c is SelectingNodesCursor) lastCursor = c.begin;
    final opt = buildTableCellNodeContext(
        operator, cellPosition, node, cursor ?? NoneCursor(), widgetIndex);
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(cell.length, (i) {
          final innerNode = cell.getNode(i);
          return Container(
            padding: EdgeInsets.only(left: innerNode.depth * 4, right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NodeDragTarget(node: innerNode, operator: opt, index: i),
                NodeDraggable(
                  index: i,
                  operator: opt,
                  child: innerNode.build(
                      opt,
                      NodeBuildParam(
                        index: i,
                        cursor: wholeSelected
                            ? null
                            : cursor?.getSingleNodeCursor(
                                i, innerNode, lastCursor),
                      ),
                      context),
                  onDragStart: () =>
                      listeners.onDrag(DragDetail(DragType.start, null)),
                  onDragEnd: () =>
                      listeners.onDrag(DragDetail(DragType.end, null)),
                  onDragUpdate: (d) =>
                      listeners.onDrag(DragDetail(DragType.dragging, d)),
                ),
                if (i == cell.length - 1)
                  NodeDragTarget(node: innerNode, operator: opt, index: i + 1),
              ],
            ),
          );
        }),
      ),
    );
  }
}
