abstract class BasicCursor {
  bool get isSelecting => this is SelectingCursor;

  bool get isEditing => this is EditingCursor;
}

abstract class NodePosition {}

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

  @override
  String toString() {
    return 'SelectingNodeCursor{index: $index, begin: $begin, end: $end}';
  }
}

class SelectingNodesCursor<T extends NodePosition> extends SelectingCursor {
  final int beginIndex;
  final T beginPosition;
  final int endIndex;
  final T endPosition;

  SelectingNodesCursor(
      this.beginIndex, this.beginPosition, this.endIndex, this.endPosition);

  @override
  String toString() {
    return 'SelectingNodesCursor{beginIndex: $beginIndex, beginPosition: $beginPosition, endIndex: $endIndex, endPosition: $endPosition}';
  }
}
