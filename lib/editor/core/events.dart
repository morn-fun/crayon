import '../cursor/basic_cursor.dart';

class EditingEvent<T extends NodePosition>{
  final EditingCursor<T> cursor;
  final EventType type;
  final dynamic extras;

  EditingEvent(this.cursor, this.type, this.extras);

  @override
  String toString() {
    return 'EditingEvent{cursor: $cursor, type: $type, extras: $extras}';
  }
}

class SelectingNodeEvent<T extends NodePosition>{
  final SelectingNodeCursor<T> cursor;
  final EventType type;
  final dynamic extras;

  SelectingNodeEvent(this.cursor, this.type, this.extras);

  @override
  String toString() {
    return 'SelectingNodeEvent{cursor: $cursor, type: $type, extras: $extras}';
  }
}

enum EventType{
  typing,
  delete,
  enter,
  selectAll,
}