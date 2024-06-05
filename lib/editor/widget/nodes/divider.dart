import 'package:crayon/editor/cursor/basic.dart';
import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../../exception/editor_node.dart';
import '../../node/divider/divider.dart';
import '../../shortcuts/arrows/arrows.dart';
import '../../../editor/extension/render_box.dart';

class DividerWidget extends StatefulWidget {
  final NodesOperator operator;
  final NodeBuildParam param;
  final DividerNode node;

  const DividerWidget(
      {super.key,
      required this.operator,
      required this.param,
      required this.node});

  @override
  State<DividerWidget> createState() => _DividerWidgetState();
}

class _DividerWidgetState extends State<DividerWidget> {
  NodesOperator get operator => widget.operator;

  NodeBuildParam get param => widget.param;

  ListenerCollection get listeners => operator.listeners;

  DividerNode get node => widget.node;

  String get nodeId => node.id;

  int get nodeIndex => param.index;

  final key = GlobalKey();

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  bool containsOffset(Offset global) =>
      renderBox?.containsOffset(global) ?? false;

  @override
  void initState() {
    super.initState();
    listeners.addGestureListener(nodeId, onGesture);
    listeners.addArrowDelegate(nodeId, onArrowAccept);
  }

  @override
  void dispose() {
    listeners.removeGestureListener(nodeId, onGesture);
    listeners.removeArrowDelegate(nodeId, onArrowAccept);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DividerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.node.id;
    final oldListeners = oldWidget.operator.listeners;
    if (oldId != nodeId || oldListeners.hashCode != listeners.hashCode) {
      logger.i('$runtimeType didUpdateWidget oldId:$oldId,  id:$nodeId');
      oldListeners.removeGestureListener(oldId, onGesture);
      oldListeners.removeArrowDelegate(oldId, onArrowAccept);
      listeners.addGestureListener(nodeId, onGesture);
      listeners.addArrowDelegate(nodeId, onArrowAccept);
    }
  }

  bool onGesture(GestureState s) {
    final offset = s.globalOffset;
    if (!containsOffset(offset)) return false;
    if (s is TapGestureState ||
        s is DoubleTapGestureState ||
        s is TripleTapGestureState) {
      operator.onCursor(
          SelectingNodeCursor(nodeIndex, node.beginPosition, node.endPosition));
    } else if (s is PanGestureState) {
      operator.onPanUpdate(EditingCursor(nodeIndex, node.beginPosition));
    }
    return true;
  }

  void onArrowAccept(AcceptArrowData data) {
    final type = data.type;
    final position = data.cursor.position;
    final offset = data.extras is Offset ? data.extras : Offset.zero;
    switch (type) {
      case ArrowType.current:
        operator.onCursor(EditingCursor(nodeIndex, position));
        break;
      case ArrowType.selectionCurrent:
        operator.onPanUpdate(EditingCursor(nodeIndex, position));
        break;
      case ArrowType.left:
      case ArrowType.selectionLeft:
        throw ArrowLeftBeginException(position);
      case ArrowType.right:
      case ArrowType.selectionRight:
        throw ArrowRightEndException(position);
      case ArrowType.up:
      case ArrowType.selectionUp:
        throw ArrowUpTopException(position, offset);
      case ArrowType.down:
      case ArrowType.selectionDown:
        throw ArrowDownBottomException(position, offset);
      case ArrowType.selectionWordNext:
      case ArrowType.selectionWordLast:
      case ArrowType.wordNext:
      case ArrowType.wordLast:
      case ArrowType.lineBegin:
      case ArrowType.lineEnd:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCursor = param.cursor != null;
    return Padding(
        key: key,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Divider(height: 2, color: hasCursor ? Colors.blue : null));
  }
}
