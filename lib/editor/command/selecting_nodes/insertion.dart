
import '../../core/command_invoker.dart';
import '../../core/controller.dart';
import '../../cursor/basic_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../node/basic_node.dart';
import '../basic_command.dart';

class InsertNodes implements BasicCommand {
  final EditingCursor cursor;
  final List<EditorNode> nodes;

  InsertNodes(this.cursor, this.nodes) : assert(nodes.isNotEmpty);

  @override
  UpdateControllerOperation? run(RichEditorController controller) {
    int index = cursor.index;
    final current = controller.getNode(index);
    final left = current.frontPartNode(cursor.position);
    final right = current.rearPartNode(cursor.position,
        newId: randomNodeId);
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
    return controller.replace(Replace(index, index + 1, copyNodes, newCursor));
  }
}

