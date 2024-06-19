import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../cursor/table.dart';
import '../../node/basic.dart';
import '../../node/table/table.dart';

class NodeDragTarget extends StatefulWidget {
  final EditorNode node;
  final NodesOperator operator;
  final DragTargetAccept<DraggableData>? onAccept;

  const NodeDragTarget({
    super.key,
    required this.node,
    required this.operator,
    this.onAccept,
  });

  @override
  State<NodeDragTarget> createState() => _NodeDragTargetState();
}

class _NodeDragTargetState extends State<NodeDragTarget> {
  EditorNode get node => widget.node;

  NodesOperator get operator => widget.operator;

  bool accepting = false;

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<DraggableData>(
      builder: (ctx, acceptedList, rejectedList) {
        return Container(
            color: accepting ? Colors.blue : Colors.transparent, height: 4);
      },
      onAccept: (v) {
        widget.onAccept?.call(v);
        accepting = false;
        refresh();
      },
      onLeave: (v) {
        accepting = false;
        refresh();
      },
      onWillAccept: (v) {
        if (v?.draggableNode is TableNode && operator is TableCellNodeContext) {
          return false;
        }
        accepting = true;
        refresh();
        return true;
      },
    );
  }
}

class DraggableData {
  final NodesOperator operator;
  final NodeDraggableSlot slot;
  final EditorNode draggableNode;

  DraggableData(this.operator, this.slot, this.draggableNode);

  int get index => slot.index;

  @override
  String toString() {
    return 'DraggableData{operator: $operator, slot: $slot, node: $draggableNode}';
  }
}

abstract class NodeDraggableSlot {
  int get index;
}

class RootNodeSlot implements NodeDraggableSlot {
  @override
  final int index;

  RootNodeSlot(this.index);
}

class TableCellNodeSlot implements RootNodeSlot {
  @override
  final int index;
  final CellPosition cellPosition;
  final int indexInCell;
  final TableNode nodeAfterDraggable;

  TableCellNodeSlot(this.index, this.cellPosition, this.indexInCell,
      this.nodeAfterDraggable);
}
