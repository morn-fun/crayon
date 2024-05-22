import 'package:crayon/editor/node/table/table.dart';
import 'package:crayon/editor/node/table/table_cell.dart';
import 'package:crayon/editor/node/table/table_cell_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TableNode basicNode({List<TableCellList>? table, List<double>? widths}) =>
      TableNode.from(
          table ??
              List.generate(
                  3,
                  (index) => TableCellList(
                      List.generate(3, (index) => TableCell.empty()))),
          List.generate(3, (index) => 200.0));

  test('', () => null);
}
