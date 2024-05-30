import 'package:flutter/material.dart';

import '../../cursor/basic.dart';

enum ArrowType {
  current,
  left,
  right,
  up,
  down,
  selectionLeft,
  selectionRight,
  selectionUp,
  selectionDown,
  nextWord,
  lastWord,
  lineBegin,
  lineEnd,
  nextWordSelection,
  lastWordSelection,
}

class AcceptArrowData {
  final String id;
  final ArrowType type;
  final ArrowType lastType;
  final SingleNodeCursor cursor;
  final dynamic extras;

  AcceptArrowData(this.id, this.type, this.cursor, this.lastType,
      {this.extras});

  @override
  String toString() {
    return 'AcceptArrowData{id: $id, type: $type, lastType: $lastType, cursor: $cursor, extras: $extras}';
  }

  AcceptArrowData newId(String id) =>
      AcceptArrowData(id, type, cursor, lastType, extras: extras);
}

typedef ArrowDelegate = void Function(AcceptArrowData arrowData);

class LeftArrowIntent extends Intent {
  const LeftArrowIntent();
}

class RightArrowIntent extends Intent {
  const RightArrowIntent();
}

class UpArrowIntent extends Intent {
  const UpArrowIntent();
}

class DownArrowIntent extends Intent {
  const DownArrowIntent();
}

class LeftSelectionArrowIntent extends Intent {
  const LeftSelectionArrowIntent();
}

class RightSelectionArrowIntent extends Intent {
  const RightSelectionArrowIntent();
}

class UpSelectionArrowIntent extends Intent {
  const UpSelectionArrowIntent();
}

class DownSelectionArrowIntent extends Intent {
  const DownSelectionArrowIntent();
}

class LastWordArrowIntent extends Intent {
  const LastWordArrowIntent();
}

class NextWordArrowIntent extends Intent {
  const NextWordArrowIntent();
}

class LineBeginArrowIntent extends Intent {
  const LineBeginArrowIntent();
}

class LineEndArrowIntent extends Intent {
  const LineEndArrowIntent();
}

class LeftWordSelectionArrowIntent extends Intent {
  const LeftWordSelectionArrowIntent();
}

class RightWordSelectionArrowIntent extends Intent {
  const RightWordSelectionArrowIntent();
}
