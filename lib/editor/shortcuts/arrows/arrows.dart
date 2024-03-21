import 'package:flutter/material.dart';

import '../../cursor/basic_cursor.dart';

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
  moveToNextWordLeft,
  moveToNextWordRight,
  moveToNextWordUp,
  moveToNextWordDown,
  nextWordSelectionLeft,
  nextWordSelectionRight,
  nextWordSelectionUp,
  nextWordSelectionDown,
}

typedef ArrowDelegate = void Function(ArrowType type, NodePosition position);

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

class LeftWordArrowIntent extends Intent {
  const LeftWordArrowIntent();
}

class RightWordArrowIntent extends Intent {
  const RightWordArrowIntent();
}

class UpWordArrowIntent extends Intent {
  const UpWordArrowIntent();
}

class DownWordArrowIntent extends Intent {
  const DownWordArrowIntent();
}

class LeftWordSelectionArrowIntent extends Intent {
  const LeftWordSelectionArrowIntent();
}

class RightWordSelectionArrowIntent extends Intent {
  const RightWordSelectionArrowIntent();
}

class UpWordSelectionArrowIntent extends Intent {
  const UpWordSelectionArrowIntent();
}

class DownWordSelectionArrowIntent extends Intent {
  const DownWordSelectionArrowIntent();
}
