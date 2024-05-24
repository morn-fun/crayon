import '../../../../editor/node/rich_text/rich_text_span.dart';
import '../../../../editor/node/table/table_cell_list.dart';
import '../../../core/copier.dart';
import '../../../core/logger.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../../shortcuts/styles.dart';
import '../../basic.dart';
import '../table.dart';
import '../table_cell.dart';
import 'common.dart';

NodeWithCursor styleRichTextNodeWhileSelecting(
    SelectingData<TablePosition> data, TableNode node, String tag) {
  final left = data.left;
  final right = data.right;
  final leftCP = left.cellPosition;
  final rightCP = right.cellPosition;
  final styleExtra =
      data.extras is StyleExtra ? data.extras : StyleExtra(false, null);
  final type = EventType.values.byName(tag);
  List<TableCellList> cellLists = [];
  if (leftCP.sameCell(rightCP)) {
    BasicCursor cursor =
        buildTableCellCursor(node.getCell(leftCP), left.cursor, right.cursor);
    final ctx = buildTableCellNodeContext(
        data.context, leftCP, node, cursor, data.index);
    onStyleEvent(ctx, RichTextTag.values.byName(tag), cursor);
    throw NodeUnsupportedException(
        node.runtimeType, 'styleRichTextNodeWhileSelecting', data);
  } else {
    for (var row = 0; row < node.rowCount; ++row) {
      var cellList = node.row(row);
      List<TableCell> cells = [];
      for (var j = 0; j < cellList.length; ++j) {
        var cell = cellList.getCell(j);
        final cellPosition = CellPosition(row, j);
        final cellCursor = node.getCursorInCell(data.cursor, cellPosition);
        if (cellCursor == null) {
          cells.add(cell);
        } else {
          final ctx = buildTableCellNodeContext(
              data.context, cellPosition, node, cellCursor, data.index);
          List<EditorNode> nodes = [];
          for (var k = 0; k < cell.length; ++k) {
            var innerNode = cell.getNode(k);
            try {
              final r = innerNode.onSelect(SelectingData(
                  SelectingNodeCursor(
                      k, innerNode.beginPosition, innerNode.endPosition),
                  type,
                  ctx,
                  extras: styleExtra));
              nodes.add(r.node);
            } on NodeUnsupportedException catch (e) {
              nodes.add(innerNode);
              logger.e(
                  '${node.runtimeType} styleRichTextNodeWhileSelecting error: ${e.message}');
            }
          }
          cells.add(cell.copy(nodes: nodes));
        }
      }
      cellLists.add(TableCellList(cells));
    }
    final newNode = node.from(cellLists, node.widths);
    final leftCell = newNode.getCell(left.cellPosition);
    final rightCell = newNode.getCell(right.cellPosition);
    return NodeWithCursor(
        newNode,
        SelectingNodeCursor(
            data.index,
            left.copy(cursor: to(leftCell.beginCursor)),
            right.copy(cursor: to(rightCell.endCursor))));
  }
}
