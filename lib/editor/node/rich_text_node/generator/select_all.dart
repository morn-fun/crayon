import '../../../cursor/rich_text_cursor.dart';
import '../../../exception/editor_node_exception.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../rich_text_node.dart';

NodeWithPosition selectAllRichTextNodeWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node) {
  int i = 0;
  final spans = node.spans;
  while(i < spans.length){
    final span = spans[i];
    if(!span.isEmpty) break;
    i++;
  }
  if(i < spans.length){
    return NodeWithPosition(node, SelectingPosition(node.beginPosition, node.endPosition));
  } else{
    throw EmptyNodeToSelectAllException(node.id);
  }
}

NodeWithPosition selectAllRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node) {
  return NodeWithPosition(node, SelectingPosition(node.beginPosition, node.endPosition));
}
