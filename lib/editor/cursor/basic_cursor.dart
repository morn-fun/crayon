abstract class BasicCursor<T extends NodePosition> {}

abstract class NodePosition {
  ///the two compare objects must be same type, or it will throw [NodePositionDifferentException]
  bool isLowerThan(NodePosition other);
}

class NoneCursor extends BasicCursor {}

abstract class SingleNodeCursor<T extends NodePosition>
    extends BasicCursor<T> {}

class EditingCursor<T extends NodePosition> extends SingleNodeCursor<T> {
  final int index;
  final T position;

  EditingCursor(this.index, this.position);

  EditingCursor<E> as<E extends NodePosition>() =>
      EditingCursor<E>(index, position as E);

  @override
  String toString() {
    return 'EditingCursor{index: $index, position: $position}';
  }
}

class SelectingNodeCursor<T extends NodePosition> extends SingleNodeCursor<T> {
  final int index;
  final T begin;
  final T end;

  SelectingNodeCursor(this.index, this.begin, this.end);

  T get left => begin.isLowerThan(end) ? begin : end;

  T get right => begin.isLowerThan(end) ? end : begin;

  SelectingNodeCursor<E> as<E extends NodePosition>() =>
      SelectingNodeCursor<E>(index, begin as E, end as E);

  @override
  String toString() {
    return 'SelectingNodeCursor{index: $index, begin: $begin, end: $end}';
  }
}

class SelectingNodesCursor<T extends NodePosition> extends BasicCursor<T> {
  final IndexWithPosition begin;
  final IndexWithPosition end;

  SelectingNodesCursor(this.begin, this.end);

  int get beginIndex => begin.index;

  NodePosition get beginPosition => begin.position;

  int get endIndex => end.index;

  NodePosition get endPosition => end.position;

  bool contains(int index) => left.index <= index && right.index >= index;

  IndexWithPosition get left => begin.index < end.index ? begin : end;

  IndexWithPosition get right => begin.index > end.index ? begin : end;

  @override
  String toString() {
    return 'SelectingNodesCursor{begin: $begin, end: $end}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectingNodesCursor &&
          runtimeType == other.runtimeType &&
          begin == other.begin &&
          end == other.end;

  @override
  int get hashCode => begin.hashCode ^ end.hashCode;
}

class IndexWithPosition {
  final int index;
  final NodePosition position;

  IndexWithPosition(this.index, this.position);

  @override
  String toString() {
    return 'IndexWithPosition{index: $index, position: $position}';
  }
}
