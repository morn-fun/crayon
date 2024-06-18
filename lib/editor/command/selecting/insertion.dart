import '../../core/command_invoker.dart';
import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../cursor/basic.dart';
import '../../exception/editor_node.dart';
import '../../node/basic.dart';
import '../basic.dart';

class InsertNodes implements BasicCommand {
  final EditingCursor cursor;
  final List<EditorNode> nodes;

  InsertNodes(this.cursor, this.nodes) : assert(nodes.isNotEmpty);

  @override
  UpdateControllerOperation? run(NodesOperator operator) {
    int index = cursor.index;
    final current = operator.getNode(index);
    final left = current.frontPartNode(cursor.position);
    final right = current.rearPartNode(cursor.position, newId: randomNodeId);
    final copyNodes = List.of(nodes);
    try {
      copyNodes[0] = left.merge(copyNodes.first);
    } on UnableToMergeException {
      copyNodes.insert(0, left);
    }
    late EditingCursor newCursor;
    try {
      final last = copyNodes.last;
      final lastIndex = copyNodes.length - 1;
      copyNodes[lastIndex] = last.merge(right);
      newCursor = EditingCursor(index + lastIndex, last.endPosition);
    } on UnableToMergeException {
      copyNodes.add(right);
      newCursor = EditingCursor(
          index + copyNodes.length - 1, copyNodes.last.endPosition);
    }
    return operator.onOperation(Replace(index, index + 1, copyNodes, newCursor));
  }
}
