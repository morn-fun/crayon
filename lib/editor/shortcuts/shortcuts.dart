import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/context.dart';
import 'delete.dart';
import 'newline.dart';
import 'redo.dart';
import 'undo.dart';

Map<ShortcutActivator, Intent> shortcuts = {
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
};

Map<Type, RichEditorControllerAction> _actions = {
  DeleteIntent: (c) => DeleteAction(c),
  UndoIntent: (c) => UndoAction(c),
  RedoIntent: (c) => RedoAction(c),
  NewlineIntent: (c) => NewlineAction(c),
};

Map<Type, Action<Intent>> getActions(EditorContext context) =>
    _actions.map((key, value) => MapEntry(key, value.call(context)));

typedef RichEditorControllerAction = Action<Intent> Function(
    EditorContext context);
