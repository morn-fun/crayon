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
import '../../shortcuts/arrows/single_arrow.dart';
import '../../shortcuts/arrows/word_arrow.dart';

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
    switch (type){
      case ArrowType.left:
      case ArrowType.up:
        if (cursor == null) return;
        final opt = buildTableCellNodeContext(
            operator, cellPosition, node, cursor, widgetIndex);
        try {
          arrowOnLeftOrUp(type, opt, runtimeType, cursor);
        } on ArrowLeftBeginException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.lastInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).endCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          arrowOnLeftOrUp(ArrowType.current, newOpt, runtimeType, newCursor);
        } on ArrowUpTopException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.lastInVertical(node, e.offset);
          final newCursor = node.getCell(newCellPosition).endCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          arrowOnLeftOrUp(ArrowType.current, newOpt, runtimeType, newCursor);
        }
        break;
      case ArrowType.right:
      case ArrowType.down:
        if (cursor == null) return;
        final opt = buildTableCellNodeContext(
            operator, cellPosition, node, cursor, widgetIndex);
        try {
          arrowOnRightOrDown(type, opt, runtimeType, cursor);
        } on ArrowRightEndException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.nextInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).beginCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          arrowOnRightOrDown(ArrowType.current, newOpt, runtimeType, newCursor);
        } on ArrowDownBottomException catch (e) {
          logger.i('onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.nextInVertical(node, e.offset);
          final newCursor = node.getCell(newCellPosition).beginCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          arrowOnRightOrDown(ArrowType.current, newOpt, runtimeType, newCursor);
        }
        break;
      case ArrowType.lastWord:
        if (cursor == null) return;
        final opt = buildTableCellNodeContext(
            operator, cellPosition, node, cursor, widgetIndex);
        try {
          wordArrowOnLeft(opt, cursor);
        } on ArrowLeftBeginException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.lastInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).endCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          arrowOnLeftOrUp(ArrowType.current, newOpt, runtimeType, newCursor);
        }
        break;
      case ArrowType.nextWord:
        if (cursor == null) return;
        final opt = buildTableCellNodeContext(
            operator, cellPosition, node, cursor, widgetIndex);
        try {
          wordArrowOnRight(opt, cursor);
        } on ArrowRightEndException catch (e) {
          logger.i(
              'Table $type onArrowAccept of ${node.runtimeType} error: ${e.message}');
          final newCellPosition = cellPosition.nextInHorizontal(node);
          final newCursor = node.getCell(newCellPosition).beginCursor;
          final newOpt = buildTableCellNodeContext(
              operator, newCellPosition, node, newCursor, widgetIndex);
          arrowOnRightOrDown(ArrowType.current, newOpt, runtimeType, newCursor);
        }
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
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(cell.length, (i) {
          final innerNode = cell.getNode(i);
          return Container(
            padding: EdgeInsets.only(left: innerNode.depth * 12, right: 4),
            child: innerNode.build(
                buildTableCellNodeContext(operator, cellPosition, node,
                    cursor ?? NoneCursor(), widgetIndex),
                NodeBuildParam(
                  index: i,
                  cursor: wholeSelected
                      ? null
                      : cursor?.getSingleNodeCursor(i, innerNode),
                ),
                context),
          );
        }),
      ),
    );
  }
}
