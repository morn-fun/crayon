abstract class BasicCursor<T extends NodePosition> {}

abstract class NodePosition {
  ///the two compare objects must be same type, or it will throw [NodePositionDifferentException]
  bool isLowerThan(NodePosition other);

  EditingCursor toCursor(int index) => EditingCursor(index, this);
}

class NoneCursor extends BasicCursor {}

abstract class SingleNodeCursor<T extends NodePosition> extends BasicCursor<T> {
  int get index;
}

class EditingCursor<T extends NodePosition> extends SingleNodeCursor<T> {
  @override
  final int index;
  final T position;

  EditingCursor(this.index, this.position);

  EditingCursor<E> as<E extends NodePosition>() =>
      EditingCursor<E>(index, position as E);

  @override
  String toString() {
    return 'EditingCursor{index: $index, position: $position}';
  }

  bool isLowerThan(EditingCursor other) {
    if (index < other.index) return true;
    if (index > other.index) return false;
    return position.isLowerThan(other.position);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditingCursor &&
          index == other.index &&
          position == other.position;

  @override
  int get hashCode => index.hashCode ^ position.hashCode;
}

class SelectingNodeCursor<T extends NodePosition> extends SingleNodeCursor<T> {
  @override
  final int index;
  final T begin;
  final T end;

  SelectingNodeCursor(this.index, this.begin, this.end);

  T get left => begin.isLowerThan(end) ? begin : end;

  T get right => begin.isLowerThan(end) ? end : begin;

  EditingCursor<T> get leftCursor => EditingCursor(index, left);

  EditingCursor<T> get rightCursor => EditingCursor(index, right);

  SelectingNodeCursor<E> as<E extends NodePosition>() =>
      SelectingNodeCursor<E>(index, begin as E, end as E);

  @override
  String toString() {
    return 'SelectingNodeCursor{index: $index, begin: $begin, end: $end}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectingNodeCursor &&
          index == other.index &&
          begin == other.begin &&
          end == other.end;

  @override
  int get hashCode => index.hashCode ^ begin.hashCode ^ end.hashCode;
}

class SelectingNodesCursor<T extends NodePosition> extends BasicCursor<T> {
  final EditingCursor begin;
  final EditingCursor end;

  SelectingNodesCursor(this.begin, this.end);

  int get beginIndex => begin.index;

  NodePosition get beginPosition => begin.position;

  int get endIndex => end.index;

  NodePosition get endPosition => end.position;

  bool contains(int index) => left.index <= index && right.index >= index;

  EditingCursor get left => begin.index < end.index ? begin : end;

  EditingCursor get right => begin.index > end.index ? begin : end;

  @override
  String toString() {
    return 'SelectingNodesCursor{begin: $begin, end: $end}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectingNodesCursor && begin == other.begin && end == other.end;

  @override
  int get hashCode => begin.hashCode ^ end.hashCode;
}
