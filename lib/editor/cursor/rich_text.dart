import '../exception/editor_node.dart';
import 'basic.dart';

class RichTextNodePosition extends NodePosition {
  final int index;
  final int offset;

  RichTextNodePosition(this.index, this.offset);

  RichTextNodePosition.empty()
      : index = -1,
        offset = -1;

  RichTextNodePosition.zero()
      : index = 0,
        offset = 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RichTextNodePosition &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          offset == other.offset;

  @override
  int get hashCode => index.hashCode ^ offset.hashCode;

  @override
  String toString() {
    return 'RichTextNodePosition{index: $index, offset: $offset}';
  }

  bool sameIndex(RichTextNodePosition other) => index == other.index;

  @override
  bool isLowerThan(NodePosition other) {
    if (other is! RichTextNodePosition) {
      throw NodePositionDifferentException(runtimeType, other.runtimeType);
    }
    if (index < other.index) return true;
    if (index > other.index) return false;
    return offset < other.offset;
  }
}
