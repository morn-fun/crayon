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
}

abstract class SelectingCursor extends BasicCursor {}

class SelectingNodeCursor<T extends NodePosition> extends SelectingCursor {
  final int index;
  final T begin;
  final T end;

  SelectingNodeCursor(this.index, this.begin, this.end);
}

class SelectingNodesCursor<T extends NodePosition> extends SelectingCursor {
  final int beginIndex;
  final T beginPosition;
  final int endIndex;
  final T endPosition;

  SelectingNodesCursor(
      this.beginIndex, this.beginPosition, this.endIndex, this.endPosition);
}
