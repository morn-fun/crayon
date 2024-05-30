import 'package:flutter/material.dart';

import '../../cursor/basic.dart';

enum ArrowType {
  current,
  left,
  right,
  up,
  down,
  selectionCurrent,
  selectionLeft,
  selectionRight,
  selectionUp,
  selectionDown,
  selectionNextWord,
  selectionLastWord,
  wordNext,
  wordLast,
  lineBegin,
  lineEnd,
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

class ArrowLeftSelectionIntent extends Intent {
  const ArrowLeftSelectionIntent();
}

class ArrowRightSelectionIntent extends Intent {
  const ArrowRightSelectionIntent();
}

class ArrowUpSelectionIntent extends Intent {
  const ArrowUpSelectionIntent();
}

class ArrowDownSelectionIntent extends Intent {
  const ArrowDownSelectionIntent();
}

class ArrowWordLastIntent extends Intent {
  const ArrowWordLastIntent();
}

class ArrowWordNextIntent extends Intent {
  const ArrowWordNextIntent();
}

class ArrowLineBeginIntent extends Intent {
  const ArrowLineBeginIntent();
}

class ArrowLineEndIntent extends Intent {
  const ArrowLineEndIntent();
}

class LeftWordSelectionArrowIntent extends Intent {
  const LeftWordSelectionArrowIntent();
}

class RightWordSelectionArrowIntent extends Intent {
  const RightWordSelectionArrowIntent();
}
