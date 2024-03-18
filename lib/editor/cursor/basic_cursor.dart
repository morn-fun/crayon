abstract class BasicCursor {
  bool get isSelecting => this is SelectingCursor;

  bool get isEditing => this is EditingCursor;
}

abstract class NodePosition {
  ///the two compare objects must be same type, or it will throw [NodePositionDifferentException]
  bool isLowerThan(NodePosition other);
}

class NoneCursor extends BasicCursor {}

class EditingCursor<T extends NodePosition> extends BasicCursor {
  final int index;
  final T position;

  EditingCursor(this.index, this.position);

  @override
  String toString() {
    return 'EditingCursor{index: $index, position: $position}';
  }
}

abstract class SelectingCursor extends BasicCursor {}

class SelectingNodeCursor<T extends NodePosition> extends SelectingCursor {
  final int index;
  final T begin;
  final T end;

  SelectingNodeCursor(this.index, this.begin, this.end);

  T get left => begin.isLowerThan(end) ? begin : end;

  T get right => begin.isLowerThan(end) ? end : begin;

  @override
  String toString() {
    return 'SelectingNodeCursor{index: $index, begin: $begin, end: $end}';
  }
}

class SelectingNodesCursor<T extends NodePosition> extends SelectingCursor {
  final IndexWithPosition<T> begin;
  final IndexWithPosition<T> end;

  SelectingNodesCursor(this.begin, this.end);

  int get beginIndex => begin.index;

  T get beginPosition => begin.position;

  int get endIndex => end.index;

  T get endPosition => end.position;

  bool contains(int index) => left.index <= index && right.index >= index;

  IndexWithPosition<T> get left => begin.index < end.index ? begin : end;

  IndexWithPosition<T> get right => begin.index > end.index ? begin : end;

  @override
  String toString() {
    return 'SelectingNodesCursor{begin: $begin, end: $end}';
  }
}

class IndexWithPosition<T extends NodePosition> {
  final int index;
  final T position;

  IndexWithPosition(this.index, this.position);

  @override
  String toString() {
    return 'IndexWithPosition{index: $index, position: $position}';
  }
}
