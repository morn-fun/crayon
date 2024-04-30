import '../../../../editor/cursor/basic.dart';
import '../../../core/copier.dart';
import '../../../cursor/node_position.dart';
import '../../../cursor/table.dart';
import '../../../shortcuts/delete.dart';
import '../../basic.dart';
import '../../rich_text/rich_text.dart';
import '../table.dart';
import '../table_cell.dart';
import 'common.dart';

// NodeWithPosition deleteWhileEditing(
//     EditingData<TablePosition> data, TableNode node) {
//   final p = data.position;
//   final cell = node.getCellByPosition(p);
//   final index = p.index;
//   final innerNode = cell.getNode(index);
//   try {
//     final r = innerNode.onEdit(EditingData(p.position, EventType.delete));
//     final singlePosition = r.position;
//     final newNode = node.updateCell(
//         p.row, p.column, (t) => cell.update(index, (t) => r.node));
//     if (singlePosition is EditingPosition) {
//       return NodeWithPosition(
//           newNode,
//           EditingPosition(p.copy(
//               position: (c) =>
//                   c.copy(position: (p) => singlePosition.position))));
//     } else if (singlePosition is SelectingPosition) {
//       final begin = p.copy(
//           position: (c) => c.copy(position: (p) => singlePosition.begin));
//       final end =
//           p.copy(position: (c) => c.copy(position: (p) => singlePosition.end));
//       return NodeWithPosition(newNode, SelectingPosition(begin, end));
//     }
//     throw NodeUnsupportedException(
//         node.runtimeType, 'deleteWhileEditing', singlePosition);
//   } on DeleteRequiresNewLineException catch (e) {
//     logger.e('${node.runtimeType}, ${e.message}');
//     if (index == 0) throw DeleteNotAllowedException(node.runtimeType);
//     final lastNode = cell.getNode(index - 1);
//     try {
//       final mergedNode = lastNode.merge(node);
//       final newNodes = [mergedNode];
//       correctDepth(cell.length, (i) => cell.getNode(i), index + 1,
//           mergedNode.depth, newNodes,
//           limitChildren: false);
//       final newNode = node.updateCell(
//           p.row,
//           p.column,
//           (t) =>
//               cell.replaceMore(index - 1, index + newNodes.length, newNodes));
//       final newPosition = p.copy(
//           position: (c) => c.copy(
//               position: (p) => lastNode.endPosition, index: (i) => i - 1));
//       return NodeWithPosition(newNode, EditingPosition(newPosition));
//     } on UnableToMergeException catch (e) {
//       logger.e('${node.runtimeType}, ${e.message}');
//       final begin = p.copy(
//           position: (c) => c.copy(
//               position: (p) => lastNode.beginPosition, index: (i) => i - 1));
//       final end = p.copy(
//           position: (c) => c.copy(
//               position: (p) => lastNode.endPosition, index: (i) => i - 1));
//       return NodeWithPosition(node, SelectingPosition(begin, end));
//     }
//   } on DeleteToChangeNodeException catch (e) {
//     logger.e('${node.runtimeType}, ${e.message}');
//     final newNode = node.updateCell(
//         p.row, p.column, (t) => cell.update(index, (t) => e.node));
//     return NodeWithPosition(newNode, EditingPosition(p));
//   }
// }

NodeWithPosition deleteWhileEditing(
    EditingData<TablePosition> data, TableNode node) {
  return operateWhileEditing(
      data, node, (c) => DeleteAction(c).invoke(DeleteIntent()));
}

NodeWithPosition deleteWhileSelecting(
    SelectingData<TablePosition> data, TableNode node) {
  final left = data.left;
  final right = data.right;
  final emptyTextNode = RichTextNode.from([]);
  if (left == node.beginPosition && right == node.endPosition) {
    return NodeWithPosition(
        emptyTextNode, EditingPosition(emptyTextNode.beginPosition));
  }
  if (left.inSameCell(right)) {
    final cell = node.getCellByPosition(left);
    final sameIndex = left.index == right.index;
    BasicCursor cursor = sameIndex
        ? SelectingNodeCursor(left.index, left.position, right.position)
        : SelectingNodesCursor(IndexWithPosition(left.index, left.position),
            IndexWithPosition(right.index, right.position));
    var newCell = cell;
    final context = cell.buildContext(
        cursor: cursor,
        listeners: data.listeners,
        onReplace: (v) {
          newCell = cell.replaceMore(v.begin, v.end, v.newNodes);
          cursor = v.cursor;
        },
        onUpdate: (v) {
          newCell = cell.update(v.index, (n) => v.node);
          cursor = v.cursor;
        },
        onCursor: (c) {
          cursor = c;
        });
    DeleteAction(context).invoke(DeleteIntent());
    return NodeWithPosition(
        node.updateCell(left.row, left.column, (t) => newCell),
        left.fromCursor(cursor));
  }
  final newNode = node.updateMore(left, right, (t) {
    return t
        .map((e) => e.updateMore(0, e.length, (m) {
              return m.map((n) => TableCell([RichTextNode.from([])])).toList();
            }))
        .toList();
  });
  return NodeWithPosition(
      newNode,
      SelectingPosition(
          left,
          right.copy(
              position: (p) => p.copy(
                  index: to(0), position: to(emptyTextNode.endPosition)))));
}
