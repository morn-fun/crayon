import '../core/command_invoker.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import '../node/basic.dart';
import 'basic.dart';

class ModifyNode implements BasicCommand {
  final NodeWithCursor nodeWithCursor;

  ModifyNode(this.nodeWithCursor);

  @override
  UpdateControllerOperation? run(NodeContext nodeContext) {
    return nodeContext.update(Update(
        nodeWithCursor.index, nodeWithCursor.node, nodeWithCursor.cursor));
  }

  @override
  String toString() {
    return 'ModifyNode{nodeWithCursor: $nodeWithCursor}';
  }
}

class ModifyNodeWithoutChangeCursor implements BasicCommand {
  final int index;
  final EditorNode node;

  ModifyNodeWithoutChangeCursor(this.index, this.node);

  @override
  UpdateControllerOperation? run(NodeContext nodeContext) {
    return nodeContext.update(Update(index, node, nodeContext.cursor));
  }

  @override
  String toString() {
    return 'ModifyNodeWithoutChangeCursor{index: $index, node: $node}';
  }
}
