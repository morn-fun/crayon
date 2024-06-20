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
  selectionWordNext,
  selectionWordLast,
  wordNext,
  wordLast,
  lineBegin,
  lineEnd,
}

class AcceptArrowData {
  final String id;
  final ArrowType type;
  final ArrowType lastType;
  final EditingCursor cursor;
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

class ArrowLeftIntent extends Intent {
  const ArrowLeftIntent();
}

class ArrowRightIntent extends Intent {
  const ArrowRightIntent();
}

class ArrowUpIntent extends Intent {
  const ArrowUpIntent();
}

class ArrowDownIntent extends Intent {
  const ArrowDownIntent();
}

class ArrowSelectionLeftIntent extends Intent {
  const ArrowSelectionLeftIntent();
}

class ArrowSelectionRightIntent extends Intent {
  const ArrowSelectionRightIntent();
}

class ArrowSelectionUpIntent extends Intent {
  const ArrowSelectionUpIntent();
}

class ArrowSelectionDownIntent extends Intent {
  const ArrowSelectionDownIntent();
}

class ArrowSelectionWordLastIntent extends Intent {
  const ArrowSelectionWordLastIntent();
}

class ArrowSelectionWordNextIntent extends Intent {
  const ArrowSelectionWordNextIntent();
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
