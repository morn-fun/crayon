import '../cursor/basic_cursor.dart';

abstract class SingleNodePosition<T extends NodePosition> {
  SingleNodeCursor<T> toCursor(int index);
}

class EditingPosition<T extends NodePosition> extends SingleNodePosition<T> {
  final T position;

  EditingPosition(this.position);

  EditingPosition<E> as<E extends NodePosition>() =>
      EditingPosition<E>(position as E);

  @override
  String toString() {
    return 'EditingPosition{position: $position}';
  }

  @override
  SingleNodeCursor<T> toCursor(int index) => EditingCursor(index, position);
}

class SelectingPosition<T extends NodePosition> extends SingleNodePosition<T> {
  final T begin;
  final T end;

  SelectingPosition(this.begin, this.end);

  T get left => begin.isLowerThan(end) ? begin : end;

  T get right => begin.isLowerThan(end) ? end : begin;

  SelectingPosition<E> as<E extends NodePosition>() =>
      SelectingPosition<E>(begin as E, end as E);

  @override
  SingleNodeCursor<T> toCursor(int index) =>
      SelectingNodeCursor(index, begin, end);

  @override
  String toString() {
    return 'SelectingPosition{begin: $begin, end: $end}';
  }
}
