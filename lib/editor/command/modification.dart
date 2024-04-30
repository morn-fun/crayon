import '../core/command_invoker.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import '../cursor/basic.dart';
import '../node/basic.dart';
import 'basic.dart';

class ModifyNode implements BasicCommand {
  final SingleNodeCursor cursor;
  final EditorNode node;

  ModifyNode(this.cursor, this.node);

  @override
  UpdateControllerOperation? run(NodeContext nodeContext) {
    return nodeContext.update(Update(cursor.index, node, cursor));
  }

  @override
  String toString() {
    return 'ModifyNode{cursor: $cursor, node: $node}';
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
