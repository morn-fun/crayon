import '../../../cursor/basic.dart';
import '../../../cursor/rich_text.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../rich_text.dart';

NodeWithCursor selectAllRichTextNodeWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node) {
  int i = 0;
  final spans = node.spans;
  while (i < spans.length) {
    final span = spans[i];
    if (!span.isEmpty) break;
    i++;
  }
  if (i < spans.length) {
    return NodeWithCursor(node,
        SelectingNodeCursor(data.index, node.beginPosition, node.endPosition));
  } else {
    throw EmptyNodeToSelectAllException(node.id);
  }
}

NodeWithCursor selectAllRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  return NodeWithCursor(node,
      SelectingNodeCursor(data.index, node.beginPosition, node.endPosition));
}
