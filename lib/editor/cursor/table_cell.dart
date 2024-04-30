import '../core/copier.dart';
import 'basic.dart';
import 'rich_text.dart';

class TableCellPosition {
  final int index;
  final NodePosition position;
  final bool atEdge;

  TableCellPosition(this.index, this.position, {this.atEdge = false});

  TableCellPosition.empty({this.atEdge = false})
      : index = -1,
        position = RichTextNodePosition.empty();

  TableCellPosition.zero({this.atEdge = false})
      : index = 0,
        position = RichTextNodePosition.zero();

  bool isLowerThan(TableCellPosition other) {
    if (index < other.index) return true;
    return position.isLowerThan(other.position);
  }

  TableCellPosition copy({
    ValueCopier<int>? index,
    ValueCopier<NodePosition>? position,
    ValueCopier<bool>? atEdge,
  }) =>
      TableCellPosition(index?.call(this.index) ?? this.index,
          position?.call(this.position) ?? this.position,
          atEdge: atEdge?.call(this.atEdge) ?? this.atEdge);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TableCellPosition &&
              runtimeType == other.runtimeType &&
              index == other.index &&
              position == other.position &&
              atEdge == other.atEdge;

  @override
  int get hashCode => index.hashCode ^ position.hashCode ^ atEdge.hashCode;

  @override
  String toString() {
    return 'TableCellPosition{index: $index, position: $position, atEdge: $atEdge}';
  }
}