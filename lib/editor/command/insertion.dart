import 'package:pre_editor/editor/core/controller.dart';

import '../cursor/basic_cursor.dart';
import '../exception/editor_node_exception.dart';
import '../node/basic_node.dart';
import 'basic_command.dart';

class InsertNodes implements BasicCommand {
  final EditingCursor cursor;
  final List<EditorNode> nodes;

  InsertNodes(this.cursor, this.nodes) : assert(nodes.isNotEmpty);

  late EditorNode _oldNode;
  late EditingCursor _newCursor;

  @override
  void execute(RichEditorController controller) {
    int index = cursor.index;
    final current = controller.getNode(index)!;
    final left = current.frontPartNode(cursor.position);
    final right = current.rearPartNode(cursor.position,
        newId: '${DateTime.now().millisecondsSinceEpoch}');
    final copyNodes = List.of(nodes);
    try {
      copyNodes[0] = left.merge(copyNodes.first);
    } on UnableToMergeException {
      copyNodes.insert(0, left);
    }
    try {
      final last = copyNodes.last;
      final lastIndex = copyNodes.length - 1;
      copyNodes[lastIndex] = last.merge(right);
      _newCursor = EditingCursor(index + lastIndex, last.endPosition);
    } on UnableToMergeException {
      copyNodes.add(right);
      _newCursor = EditingCursor(
          index + copyNodes.length - 1, copyNodes.last.endPosition);
    }
    controller.replaceOne(ReplaceOneData(index, copyNodes, _newCursor));
    _oldNode = current;
  }

  @override
  void undo(RichEditorController controller) {
    controller.replaceMore(
        ReplaceMoreData(cursor.index, _newCursor.index, [_oldNode], cursor));
  }
}

class InsertNewline implements BasicCommand {
  final EditingCursor cursor;

  InsertNewline(this.cursor);

  late EditorNode _oldNode;
  late EditingCursor _newCursor;

  @override
  void execute(RichEditorController controller) {
    int index = cursor.index;
    final current = controller.getNode(index)!;
    final left = current.frontPartNode(cursor.position);
    final right = current.rearPartNode(cursor.position,
        newId: '${DateTime.now().millisecondsSinceEpoch}');
    _newCursor = EditingCursor(index + 1, right.beginPosition);
    controller.replaceOne(ReplaceOneData(index, [left, right], _newCursor));
    _oldNode = current;
  }

  @override
  void undo(RichEditorController controller) {
    controller.replaceMore(
        ReplaceMoreData(cursor.index, _newCursor.index, [_oldNode], cursor));
  }
}
