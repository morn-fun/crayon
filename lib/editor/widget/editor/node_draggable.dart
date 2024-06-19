import 'package:crayon/editor/cursor/basic.dart';
import 'package:flutter/material.dart';

import '../../core/context.dart';
import 'node_drag_target.dart';

class NodeDraggable extends StatefulWidget {
  final int index;
  final NodesOperator operator;
  final Widget child;
  final DragUpdateCallback? onDragUpdate;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragStart;
  final NodeDraggableSlot slot;
  final bool draggable;

  const NodeDraggable({
    super.key,
    required this.index,
    required this.operator,
    required this.child,
    required this.slot,
    this.onDragUpdate,
    this.onDragStart,
    this.onDragEnd,
    this.draggable = true,
  });

  @override
  State<NodeDraggable> createState() => _NodeDraggableState();
}

class _NodeDraggableState extends State<NodeDraggable> {
  int get index => widget.index;

  NodesOperator get operator => widget.operator;

  Widget get child => widget.child;

  bool hovering = false;
  bool dragging = false;

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final node = operator.getNode(index);
    return MouseRegion(
      onEnter: (v) {
        hovering = true;
        refresh();
      },
      onExit: (v) {
        hovering = false;
        refresh();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: (hovering || dragging) && widget.draggable
                ? Draggable<DraggableData>(
                    affinity: Axis.vertical,
                    data: DraggableData(operator, widget.slot, node),
                    onDragStarted: () {
                      operator.onCursor(NoneCursor());
                      dragging = true;
                      refresh();
                      widget.onDragStart?.call();
                    },
                    onDragEnd: (v) => endDragging(),
                    onDragUpdate: (v) => widget.onDragUpdate?.call(v),
                    onDraggableCanceled: (v, o) => endDragging(),
                    onDragCompleted: () => endDragging(),
                    feedback: Material(
                        child: MouseRegion(
                      cursor: SystemMouseCursors.grabbing,
                      child: Container(
                        foregroundDecoration:
                            BoxDecoration(color: Colors.white.withOpacity(0.5)),
                        child: node.build(
                            operator,
                            NodeBuildParam(index: index, cursor: null),
                            context),
                      ),
                    )),
                    childWhenDragging: Container(),
                    child: MouseRegion(
                      child: Padding(
                        child: Icon(Icons.drag_indicator_rounded),
                        padding: EdgeInsets.only(top: 4),
                      ),
                      cursor: SystemMouseCursors.grab,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Container(
              foregroundDecoration: dragging
                  ? BoxDecoration(color: Colors.white.withOpacity(0.5))
                  : null,
              child: IgnorePointer(ignoring: dragging, child: child),
            ),
          )
        ],
      ),
    );
  }

  void endDragging() {
    dragging = false;
    refresh();
    widget.onDragEnd?.call();
  }
}
