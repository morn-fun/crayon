import 'package:flutter/material.dart';
import '../../../../editor/core/context.dart';
import '../../../../editor/core/listener_collection.dart';
import '../../../../editor/cursor/basic.dart';
import '../../../../editor/extension/cursor.dart';
import '../../command/modification.dart';
import '../../cursor/table.dart';
import '../../exception/editor_node.dart';
import '../../node/table/table.dart';
import '../../node/table/table_cell.dart' as tc;

class RichTableCell extends StatefulWidget {
  final tc.TableCell cell;
  final TableNode node;
  final CellIndex cellIndex;
  final NodeContext context;
  final NodeBuildParam param;
  final BasicCursor? cursor;
  final ListenerCollection listeners;

  const RichTableCell({
    super.key,
    required this.cell,
    required this.node,
    required this.cellIndex,
    required this.context,
    required this.param,
    required this.cursor,
    required this.listeners,
  });

  @override
  State<RichTableCell> createState() => _RichTableCellState();
}

class _RichTableCellState extends State<RichTableCell> {
  NodeContext get nodeContext => widget.context;

  ListenerCollection get listeners => widget.listeners;

  tc.TableCell get cell => widget.cell;

  BasicCursor? get cursor => widget.cursor;

  TableNode get node => widget.node;

  CellIndex get cellIndex => widget.cellIndex;

  int get index => widget.param.index;

  late tc.TableCellNodeContext cellContext;

  @override
  void initState() {
    cellContext = tc.TableCellNodeContext(
      () => cursor ?? NoneCursor(),
      () => cell,
      listeners,
      (v) {
        final newCell = cell.replaceMore(v.begin, v.end, v.newNodes);
        nodeContext.execute(ModifyNode(
            _cursorToCursor(v.cursor, cellIndex, index),
            node.updateCell(cellIndex.row, cellIndex.column, (t) => newCell)));
      },
      (v) {
        final newCell = cell.update(v.index, (n) => v.node);
        nodeContext.execute(ModifyNode(
            _cursorToCursor(v.cursor, cellIndex, index),
            node.updateCell(cellIndex.row, cellIndex.column, (t) => newCell)));
      },
      (newCursor) {
        nodeContext.onCursor(_cursorToCursor(newCursor, cellIndex, index));
      },
      (v) {
        nodeContext.onCursorOffset(v);
      },
      (v) {
        nodeContext
            .onPanUpdate(EditingCursor(index, TablePosition(cellIndex, v)));
      },
    );

    nodeContext.addContext(cell.id, cellContext);
    super.initState();
  }

  @override
  void dispose() {
    nodeContext.removeContext(cell.id, cellContext);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool wholeSelected = false;
    final c = cursor;
    if (c is SelectingNodesCursor) {
      if (cell.wholeSelected(c.begin, c.right)) wholeSelected = true;
    }
    return Container(
      foregroundDecoration: wholeSelected
          ? BoxDecoration(color: Colors.blue.withOpacity(0.5))
          : null,
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(cell.length, (i) {
          final innerNode = cell.getNode(i);
          return Container(
            padding: EdgeInsets.only(left: innerNode.depth * 12, right: 4),
            child: innerNode.build(
                cellContext,
                NodeBuildParam(
                    index: i,
                    position: cursor?.getSingleNodePosition(i, innerNode)),
                context),
          );
        }),
      ),
    );
  }
}

SingleNodeCursor<TablePosition> _cursorToCursor(
    BasicCursor cursor, CellIndex cellIndex, int index) {
  if (cursor is EditingCursor) {
    return EditingCursor(index, TablePosition(cellIndex, cursor));
  } else if (cursor is SelectingNodeCursor) {
    final i = cursor.index;
    return SelectingNodeCursor(
        index,
        TablePosition(cellIndex, EditingCursor(i, cursor.left)),
        TablePosition(cellIndex, EditingCursor(i, cursor.right)));
  } else if (cursor is SelectingNodesCursor) {
    return SelectingNodeCursor(index, TablePosition(cellIndex, cursor.left),
        TablePosition(cellIndex, cursor.right));
  }
  throw NodeUnsupportedException(cursor.runtimeType,
      'from cursor:$cursor to table cursor', '$cellIndex,  index:$index');
}
