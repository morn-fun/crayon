import '../exception/editor_node.dart';
import 'basic.dart';

class CodeBlockPosition implements NodePosition {
  final int index;
  final int offset;
  final bool inEdge;

  CodeBlockPosition(this.index, this.offset, {this.inEdge = false});

  CodeBlockPosition.empty({this.inEdge = false})
      : index = -1,
        offset = -1;

  CodeBlockPosition.zero({this.inEdge = false})
      : index = 0,
        offset = 0;

  CodeBlockPosition copy({int? index, int? offset, bool? inEdge}) =>
      CodeBlockPosition(index ?? this.index, offset ?? this.offset,
          inEdge: inEdge ?? this.inEdge);

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
          inEdge == other.inEdge;

  @override
  int get hashCode => index.hashCode ^ offset.hashCode ^ inEdge.hashCode;

  @override
  String toString() {
    return 'CodeBlockPosition{index: $index, offset: $offset, inEdge: $inEdge}';
  }
}
