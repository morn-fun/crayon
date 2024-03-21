import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/context.dart';
import 'arrows/single_arrow.dart';
import 'delete.dart';
import 'arrows/arrows.dart';
import 'newline.dart';
import 'redo.dart';
import 'select_all.dart';
import 'undo.dart';

Map<ShortcutActivator, Intent> editorShortcuts = {

  ///single arrow
  const SingleActivator(LogicalKeyboardKey.arrowLeft): const LeftArrowIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowRight):
      const RightArrowIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowUp): const UpArrowIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowDown): const DownArrowIntent(),

  ///TODO:selection arrow
  ///TODO:word arrow
  ///TODO:word selection arrow

  const SingleActivator(LogicalKeyboardKey.backspace): const DeleteIntent(),
  const SingleActivator(LogicalKeyboardKey.enter): const NewlineIntent(),
  LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyZ):
      const UndoIntent(),
  LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.shift,
      LogicalKeyboardKey.keyZ): const RedoIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
      const UndoIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
      LogicalKeyboardKey.keyZ): const RedoIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
      const SelectAllIntent(),
  LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyA):
      const SelectAllIntent(),
};

Map<Type, RichEditorControllerAction> _actions = {
  DeleteIntent: (c) => DeleteAction(c),
  UndoIntent: (c) => UndoAction(c),
  RedoIntent: (c) => RedoAction(c),
  NewlineIntent: (c) => NewlineAction(c),
  LeftArrowIntent: (c) => LeftArrowAction(c),
  RightArrowIntent: (c) => RightArrowAction(c),
  UpArrowIntent: (c) => UpArrowAction(c),
  DownArrowIntent: (c) => DownArrowAction(c),
  SelectAllIntent: (c) => SelectAllAction(c),
};

Map<Type, Action<Intent>> getActions(EditorContext context) =>
    _actions.map((key, value) => MapEntry(key, value.call(context)));

typedef RichEditorControllerAction = Action<Intent> Function(
    EditorContext context);
