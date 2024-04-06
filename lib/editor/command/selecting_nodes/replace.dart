import 'package:pre_editor/editor/node/position_data.dart';

import '../../core/command_invoker.dart';
import '../../core/controller.dart';
import '../../core/logger.dart';
import '../../cursor/basic_cursor.dart';
import '../../exception/editor_node_exception.dart';
import '../../node/basic_node.dart';
import '../basic_command.dart';

class ReplaceSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;
  final EventType type;
  final dynamic extra;

  ReplaceSelectingNodes(this.cursor, this.type, this.extra);

  @override
  UpdateControllerCommand? run(RichEditorController controller) {
    final left = cursor.left;
    final right = cursor.right;
    final leftNode = controller.getNode(left.index);
    final rightNode = controller.getNode(right.index);
    final newLeftNP = leftNode.onSelect(SelectingData(
        SelectingPosition(left.position, leftNode.endPosition), type,
        extras: extra));
    final newRight =
        rightNode.rearPartNode(right.position, newId: randomNodeId);
    final newCursor = newLeftNP.position.toCursor(left.index);
    try {
      final newNode = newLeftNP.node.merge(newRight);
      return controller
          .replace(Replace(left.index, right.index + 1, [newNode], newCursor));
    } on UnableToMergeException catch (e) {
      logger.e('$runtimeType error: $e');
      return controller.replace(Replace(
          left.index, right.index + 1, [newLeftNP.node, newRight], newCursor));
    }
  }
}
