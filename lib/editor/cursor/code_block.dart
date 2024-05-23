import '../exception/editor_node.dart';
import 'basic.dart';

class CodeBlockPosition extends NodePosition {
  final int index;
  final int offset;
  final bool atEdge;

  CodeBlockPosition(this.index, this.offset, {this.atEdge = false});

  CodeBlockPosition.zero({this.atEdge = false})
      : index = 0,
        offset = 0;

  CodeBlockPosition copy({int? index, int? offset, bool? atEdge}) =>
      CodeBlockPosition(index ?? this.index, offset ?? this.offset,
          atEdge: atEdge ?? this.atEdge);

  @override
  bool isLowerThan(NodePosition other) {
    if (other is! CodeBlockPosition) {
      throw NodePositionDifferentException(runtimeType, other.runtimeType);
    }
    if (index < other.index) return true;
    if (index > other.index) return false;
    return offset < other.offset;
  }

  bool sameIndex(CodeBlockPosition other) => index == other.index;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeBlockPosition &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          offset == other.offset &&
          atEdge == other.atEdge;

  @override
  int get hashCode => index.hashCode ^ offset.hashCode ^ atEdge.hashCode;

  @override
  String toString() {
    return 'CodeBlockPosition{index: $index, offset: $offset, atEdge: $atEdge}';
  }
}
