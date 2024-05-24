import 'package:flutter/material.dart';
import '../../../../editor/core/context.dart';
import '../../../../editor/core/listener_collection.dart';
import '../../../../editor/cursor/basic.dart';
import '../../../../editor/extension/cursor.dart';
import '../../core/logger.dart';
import '../../cursor/table.dart';
import '../../node/table/generator/common.dart';
import '../../node/table/table.dart';
import '../../node/table/table_cell.dart' as tc;
import '../../shortcuts/arrows/arrows.dart';

class RichTableCell extends StatefulWidget {
  final tc.TableCell cell;
  final TableNode node;
  final CellPosition cellPosition;
  final NodeBuildParam param;
  final BasicCursor? cursor;
  final ListenerCollection listeners;
  final NodesOperator context;
  final String cellId;

  const RichTableCell({
    super.key,
    required this.cell,
    required this.cellId,
    required this.node,
    required this.cellPosition,
    required this.context,
    required this.param,
    required this.cursor,
    required this.listeners,
  });

  @override
  State<RichTableCell> createState() => _RichTableCellState();
}

class _RichTableCellState extends State<RichTableCell> {
  NodesOperator get nodeContext => widget.context;

  ListenerCollection get listeners => widget.listeners;

  tc.TableCell get cell => widget.cell;

  BasicCursor? get cursor => widget.cursor;

  TableNode get node => widget.node;

  CellPosition get cellPosition => widget.cellPosition;

  int get index => widget.param.index;

  String get cellId => widget.cellId;

  late TableCellNodeContext cellContext;

  late ListenerCollection localListeners;

  @override
  void initState() {
    logger.i('$cellId  init');
    localListeners = listeners.copy(
        nodeListeners: {},
        nodesListeners: {},
        gestureListeners: {},
        arrowDelegates: {});
    listeners.addGestureListener(cellId, onGesture);
    listeners.addArrowDelegate(cellId, onArrowAccept);
    nodeContext.listeners.addListener(cellId, localListeners);
    super.initState();
  }

  void onGesture(GestureState s) => localListeners.notifyGestures(s);

  void onArrowAccept(AcceptArrowData d) {}

  @override
  void didUpdateWidget(covariant RichTableCell oldWidget) {
    // logger.i(
    //     'onTableUpdateWidget , old:${oldWidget.cellId} ${oldWidget.cellPosition},  new:$cellId, $cellPosition');
    final oldListeners = oldWidget.listeners;
    if (oldListeners.hashCode != listeners.hashCode) {
      oldListeners.removeGestureListener(node.id, onGesture);
      oldListeners.removeArrowDelegate(node.id, onArrowAccept);
      listeners.addGestureListener(node.id, onGesture);
      listeners.addArrowDelegate(node.id, onArrowAccept);
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
    nodeContext.listeners.removeListener(cellId, localListeners);
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
                buildTableCellNodeContext(nodeContext, cellPosition, node,
                    cursor ?? NoneCursor(), index),
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
