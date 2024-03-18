import 'package:pre_editor/editor/core/controller.dart';

import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import '../node/basic_node.dart';
import '../node/rich_text_node/rich_text_node.dart';
import 'basic_command.dart';

class InsertNodes implements BasicCommand {
  final EditingCursor cursor;
  final List<EditorNode> nodes;

  InsertNodes(this.cursor, this.nodes) : assert(nodes.isNotEmpty);

  @override
  void run(RichEditorController controller) {
    int index = cursor.index;
    final current = controller.getNode(index);
    final left = current.frontPartNode(cursor.position);
    final right = current.rearPartNode(cursor.position,
        newId: '${DateTime.now().millisecondsSinceEpoch}');
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
    controller.replace(Replace(index, index + 1, copyNodes, newCursor));
  }
}

class InsertNewline implements BasicCommand {
  final EditingCursor cursor;

  InsertNewline(this.cursor);

  @override
  void run(RichEditorController controller) {
    int index = cursor.index;
    final current = controller.getNode(index);
    final left = current.frontPartNode(cursor.position);
    final right = current.rearPartNode(cursor.position,
        newId: '${DateTime.now().millisecondsSinceEpoch}');
    controller.replace(Replace(index, index + 1, [left, right],
        EditingCursor(index + 1, right.beginPosition)));
  }
}

class InsertNewLineWhileSelectingNode implements BasicCommand {
  final SelectingNodeCursor cursor;

  InsertNewLineWhileSelectingNode(this.cursor);

  @override
  void run(RichEditorController controller) {
    int index = cursor.index;
    final current = controller.getNode(index);
    final left = current.frontPartNode(cursor.left);
    final right = current.rearPartNode(cursor.right,
        newId: '${DateTime.now().millisecondsSinceEpoch}');
    controller.replace(Replace(index, index + 1, [left, right],
        EditingCursor(index + 1, right.beginPosition)));
  }
}

class InsertNewLineWhileSelectingNodes implements BasicCommand {
  final SelectingNodesCursor cursor;

  InsertNewLineWhileSelectingNodes(this.cursor);

  @override
  void run(RichEditorController controller) {
    final leftCursor = cursor.left;
    final rightCursor = cursor.right;
    final leftNode = controller.getNode(leftCursor.index);
    final rightNode = controller.getNode(rightCursor.index);
    final left = leftNode.frontPartNode(leftCursor.position);
    final right = rightNode.rearPartNode(rightCursor.position,
        newId: '${DateTime.now().millisecondsSinceEpoch}');
    controller.replace(Replace(
        leftCursor.index,
        rightCursor.index + 1,
        [left, right],
        EditingCursor(leftCursor.index + 1, right.beginPosition)));
  }
}
