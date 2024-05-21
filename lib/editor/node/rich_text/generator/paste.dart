import '../../../cursor/basic.dart';
import '../../../cursor/rich_text.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../rich_text.dart';

NodeWithCursor pasteWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node) {
  final extra = data.extras as List<EditorNode>, position = data.position;
  if (extra.isEmpty) {
    throw NodeUnsupportedException(
        node.runtimeType, 'pasteWhileEditing without extra', data);
  }
  final leftNode = node.frontPartNode(position),
      rightNode = node.rearPartNode(position, newId: randomNodeId);
  if (extra.length == 1) {
    try {
      final newLeftNode = leftNode.merge(extra.first);
      final newNode = newLeftNode.merge(rightNode);
      return NodeWithCursor(
          newNode, EditingCursor(data.index, newLeftNode.endPosition));
    } on UnableToMergeException {
      throw PasteToCreateMoreNodesException([leftNode, extra.first, rightNode],
          node.runtimeType, rightNode.beginPosition);
    }
  } else {
    final newNodes = <EditorNode>[];
    try {
      final newLeft = leftNode.merge(extra.first);
      newNodes.add(newLeft);
    } on UnableToMergeException {
      newNodes.add(leftNode);
      newNodes.add(extra.first);
    }
    newNodes.addAll(extra.sublist(1, extra.length - 1));
    NodePosition position = extra.last.endPosition;
    try {
      final newRight = extra.last.merge(rightNode);
      newNodes.add(newRight);
    } on UnableToMergeException {
      newNodes.add(extra.last);
      newNodes.add(rightNode);
      position = rightNode.beginPosition;
    }
    throw PasteToCreateMoreNodesException(newNodes, node.runtimeType, position);
  }
}

NodeWithCursor pasteWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  final extra = data.extras as List<EditorNode>, position = data.cursor;
  if (extra.isEmpty) {
    throw NodeUnsupportedException(
        node.runtimeType, 'pasteWhileSelecting without extra', data);
  }
  final leftNode = node.frontPartNode(position.left),
      rightNode = node.rearPartNode(position.right, newId: randomNodeId);
  if (extra.length == 1) {
    try {
      final newLeftNode = leftNode.merge(extra.first);
      final newNode = newLeftNode.merge(rightNode);
      return NodeWithCursor(
          newNode, EditingCursor(position.index, newLeftNode.endPosition));
    } on UnableToMergeException {
      throw PasteToCreateMoreNodesException([leftNode, extra.first, rightNode],
          node.runtimeType, rightNode.beginPosition);
    }
  } else {
    final newNodes = <EditorNode>[];
    try {
      final newLeft = leftNode.merge(extra.first);
      newNodes.add(newLeft);
    } on UnableToMergeException {
      newNodes.add(leftNode);
      newNodes.add(extra.first);
    }
    newNodes.addAll(extra.sublist(1, extra.length - 1));
    NodePosition position = extra.last.endPosition;
    try {
      final newRight = extra.last.merge(rightNode);
      newNodes.add(newRight);
    } on UnableToMergeException {
      newNodes.add(extra.last);
      newNodes.add(rightNode);
      position = rightNode.beginPosition;
    }
    throw PasteToCreateMoreNodesException(newNodes, node.runtimeType, position);
  }
}
