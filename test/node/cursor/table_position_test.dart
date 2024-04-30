import 'package:crayon/editor/cursor/table.dart';
import 'package:crayon/editor/cursor/table_cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TablePosition', () {
    test('Equality', () {
      final position1 = TablePosition(1, 2, TableCellPosition.zero());
      final position2 = TablePosition(1, 2, TableCellPosition.zero());
      final position3 =
          TablePosition(1, 2, TableCellPosition.zero(atEdge: true));

      expect(position1, equals(position2));
      expect(position1 == position3, isFalse);
    });

    test('Hash code', () {
      final position1 = TablePosition(1, 2, TableCellPosition.zero());
      final position2 = TablePosition(1, 2, TableCellPosition.zero());
      final position3 =
          TablePosition(1, 2, TableCellPosition.zero(atEdge: true));

      expect(position1.hashCode, equals(position2.hashCode));
      expect(position1.hashCode == position3.hashCode, isFalse);
    });

    test('isLowerThan', () {
      final position1 = TablePosition(1, 2, TableCellPosition.zero());
      final position2 = TablePosition(2, 2, TableCellPosition.zero());
      final position3 = TablePosition(1, 3, TableCellPosition.zero());
      final position4 = TablePosition(1, 2, TableCellPosition.zero());
      final position5 = TablePosition(1, 2, TableCellPosition.zero());

      expect(position1.isLowerThan(position2), isTrue);
      expect(position1.isLowerThan(position3), isTrue);
      expect(position1.isLowerThan(position4), isTrue);
      expect(position1.isLowerThan(position5), isFalse);
    });
  });
}
