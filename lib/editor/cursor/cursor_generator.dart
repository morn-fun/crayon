import 'basic_cursor.dart';

BasicCursor? generateSelectingCursor(
    BasicCursor oldCursor, NodePosition endPosition, int index) {
  BasicCursor? newCursor;
  if (oldCursor is EditingCursor) {
    if (index == oldCursor.index) {
      newCursor = SelectingNodeCursor(index, oldCursor.position, endPosition);
    } else {
      newCursor = SelectingNodesCursor(
          IndexWithPosition(oldCursor.index, oldCursor.position),
          IndexWithPosition(index, endPosition));
    }
  } else if (oldCursor is SelectingNodeCursor) {
    if (index == oldCursor.index) {
      newCursor = SelectingNodeCursor(index, oldCursor.begin, endPosition);
    } else {
      newCursor = SelectingNodesCursor(
          IndexWithPosition(oldCursor.index, oldCursor.begin),
          IndexWithPosition(index, endPosition));
    }
  } else if (oldCursor is SelectingNodesCursor) {
    newCursor = SelectingNodesCursor(
        IndexWithPosition(oldCursor.beginIndex, oldCursor.beginPosition),
        IndexWithPosition(index, endPosition));
  }
  return newCursor;
}
