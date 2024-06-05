import '../exception/editor_node.dart';
import 'basic.dart';

class DividerPosition extends NodePosition {
  @override
  bool isLowerThan(NodePosition other) {
    if (other is! DividerPosition) {
      throw NodePositionDifferentException(runtimeType, other.runtimeType);
    }
    throw NodeUnsupportedException(runtimeType, 'isLowerThan', null);
  }
}

final dividerPosition = DividerPosition();
