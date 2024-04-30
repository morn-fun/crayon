import '../../../cursor/basic.dart';
import '../../../cursor/rich_text.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../../../cursor/node_position.dart';
import '../rich_text.dart';

NodeWithPosition pasteWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node) {
  final extra = data.extras as List<EditorNode>, position = data.position;
  if (extra.isEmpty) return NodeWithPosition(node, EditingPosition(position));
  final leftNode = node.frontPartNode(position),
      rightNode = node.rearPartNode(position, newId: randomNodeId);
  if (extra.length == 1) {
    try {
      final newLeftNode = leftNode.merge(extra.first);
      final newNode = newLeftNode.merge(rightNode);
      return NodeWithPosition(
          newNode, EditingPosition(newLeftNode.endPosition));
    } on UnableToMergeException {
      throw UnablePasteException([leftNode, extra.first, rightNode],
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
    throw UnablePasteException(newNodes, node.runtimeType, position);
  }
}

NodeWithPosition pasteWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  final extra = data.extras as List<EditorNode>, position = data.position;
  var result = NodeWithPosition(node, EditingPosition(data.left));
  if (extra.isEmpty) return result;
  final leftNode = node.frontPartNode(position.left),
      rightNode = node.rearPartNode(position.right, newId: randomNodeId);
  if (extra.length == 1) {
    try {
      final newLeftNode = leftNode.merge(extra.first);
      final newNode = newLeftNode.merge(rightNode);
      return NodeWithPosition(
          newNode, EditingPosition(newLeftNode.endPosition));
    } on UnableToMergeException {
      throw UnablePasteException([leftNode, extra.first, rightNode],
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
    throw UnablePasteException(newNodes, node.runtimeType, position);
  }
}
