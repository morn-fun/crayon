import 'package:flutter/material.dart';

import '../../command/reordering.dart';
import '../../core/context.dart';
import '../../node/basic.dart';

class NodeDragTarget extends StatefulWidget {
  final EditorNode node;
  final NodesOperator operator;
  final int index;

  const NodeDragTarget({
    super.key,
    required this.node,
    required this.operator,
    required this.index,
  });

  @override
  State<NodeDragTarget> createState() => _NodeDragTargetState();
}

class _NodeDragTargetState extends State<NodeDragTarget> {
  EditorNode get node => widget.node;

  NodesOperator get operator => widget.operator;

  int get index => widget.index;

  bool accepting = false;

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<OperatorWithIndex>(
      builder: (ctx, acceptedList, rejectedList) {
        return Container(
            color: accepting ? Colors.blue : Colors.transparent, height: 4);
      },
      onAccept: (v) {
        if (v.operator == operator) {
          operator.execute(MoveNode(v.index, index));
        }
        accepting = false;
        refresh();
      },
      onLeave: (v) {
        accepting = false;
        refresh();
      },
      onWillAccept: (v) {
        accepting = true;
        refresh();
        return true;
      },
    );
  }
}

class OperatorWithIndex {
  final NodesOperator operator;
  final int index;

  OperatorWithIndex(this.operator, this.index);

  @override
  String toString() {
    return 'OperatorWithIndex{operator: $operator, index: $index}';
  }
}
