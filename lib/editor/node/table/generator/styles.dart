import '../../../../editor/extension/cursor.dart';
import '../../../../editor/node/table/table_cell_list.dart';

import '../../../core/copier.dart';
import '../../../cursor/node_position.dart';
import '../../../cursor/table.dart';
import '../../basic.dart';
import '../table.dart';
import '../table_cell.dart';

NodeWithPosition styleRichTextNodeWhileSelecting(
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
      final ctx = data.context.getChildContext(cell.id)!;
      final cellIndex = CellPosition(i, j);
      final cursor = cell.getCursor(data.position, cellIndex);
      if (cursor == null) {
        cells.add(cell);
      } else {
        List<EditorNode> nodes = [];
        for (var k = 0; k < cell.length; ++k) {
          var innerNode = cell.getNode(k);
          final p = cursor.getSingleNodePosition(k, innerNode);
          if (p == null || p is EditingPosition) {
            nodes.add(innerNode);
          } else {
            final r = innerNode
                .onSelect(SelectingData(p as SelectingPosition, type, ctx));
            nodes.add(r.node);
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
  return NodeWithPosition(
      newNode,
      SelectingPosition(left.copy(cursor: to(leftCell.beginCursor)),
          right.copy(cursor: to(rightCell.endCursor))));
}
