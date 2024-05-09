import 'package:flutter/material.dart';
import '../../../../editor/core/context.dart';
import '../../../../editor/core/listener_collection.dart';
import '../../../../editor/cursor/basic.dart';
import '../../core/editor_controller.dart';
import '../../node/table/table_cell.dart' as tc;
import '../editor/shared_node_context_widget.dart';

class RichTableCell extends StatefulWidget {
  final ValueGetter<tc.TableCell> cellGetter;
  final ValueGetter<BasicCursor> cursorGetter;
  final NodeContext nodeContext;
  final ListenerCollection listeners;
  final ValueChanged<Replace> onReplace;
  final ValueChanged<Update> onUpdate;
  final ValueChanged<BasicCursor> onCursor;
  final Widget child;
  final String id;

  const RichTableCell({
    super.key,
    required this.cellGetter,
    required this.id,
    required this.nodeContext,
    required this.cursorGetter,
    required this.listeners,
    required this.onReplace,
    required this.onUpdate,
    required this.onCursor,
    required this.child,
  });

  @override
  State<RichTableCell> createState() => _RichTableCellState();
}

class _RichTableCellState extends State<RichTableCell> {
  NodeContext get nodeContext => widget.nodeContext;

  ListenerCollection get listeners => widget.listeners;

  late tc.TableCellNodeContext cellContext;

  @override
  void initState() {
    cellContext = tc.TableCellNodeContext(
        widget.cursorGetter,
        widget.cellGetter,
        listeners,
        widget.onReplace,
        widget.onUpdate,
        widget.onCursor);
    nodeContext.addContext(widget.id, cellContext);
    super.initState();
  }

  @override
  void dispose() {
    nodeContext.removeContext(widget.id, cellContext);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShareNodeContextWidget(context: cellContext, child: widget.child);
  }
}
