import '../../../../editor/extension/cursor.dart';
import '../../../../editor/node/table/table_cell_list.dart';

import '../../../core/copier.dart';
import '../../../core/logger.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/table.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../table.dart';
import '../table_cell.dart';
import 'common.dart';

NodeWithCursor styleRichTextNodeWhileSelecting(
    SelectingData<TablePosition> data, TableNode node, String tag) {
  final left = data.left;
  final right = data.right;
  final type = EventType.values.byName(tag);
  List<TableCellList> cellLists = [];
  for (var i = 0; i < node.table.length; ++i) {
    var cellList = node.table[i];
    List<TableCell> cells = [];
    for (var j = 0; j < cellList.length; ++j) {
      var cell = cellList.getCell(j);
      final cellIndex = CellPosition(i, j);
      final cursor = cell.getCursor(data.cursor, cellIndex);
      if (cursor == null) {
        cells.add(cell);
      } else {
        final ctx = buildTableCellNodeContext(
            data.context, cellIndex, node, cursor, data.index);
        List<EditorNode> nodes = [];
        for (var k = 0; k < cell.length; ++k) {
          var innerNode = cell.getNode(k);
          final p = cursor.getSingleNodeCursor(k, innerNode);
          if (p == null || p is EditingCursor) {
            nodes.add(innerNode);
          } else {
            try {
              final r = innerNode
                  .onSelect(SelectingData(p as SelectingNodeCursor, type, ctx));
              nodes.add(r.node);
            } on NodeUnsupportedException catch (e) {
              nodes.add(innerNode);
              logger.e(
                  '${node.runtimeType} styleRichTextNodeWhileSelecting error: ${e.message}');
            }
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
