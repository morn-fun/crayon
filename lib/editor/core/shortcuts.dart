import 'dart:io';

import 'package:crayon/editor/shortcuts/arrows/selection_arrow.dart';
import 'package:crayon/editor/shortcuts/arrows/word_arrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shortcuts/arrows/line_arrow.dart';
import '../shortcuts/optional_menu.dart';
import 'context.dart';
import '../shortcuts/arrows/single_arrow.dart';
import '../shortcuts/copy_paste.dart';
import '../shortcuts/delete.dart';
import '../shortcuts/arrows/arrows.dart';
import '../shortcuts/newline.dart';
import '../shortcuts/redo.dart';
import '../shortcuts/select_all.dart';
import '../shortcuts/styles.dart';
import '../shortcuts/tab.dart';
import '../shortcuts/undo.dart';

final Map<ShortcutActivator, Intent> editorShortcuts = {
  ///single arrow
  const SingleActivator(LogicalKeyboardKey.arrowLeft): const LeftArrowIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowRight):
      const RightArrowIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowUp): const UpArrowIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowDown): const DownArrowIntent(),

  if (Platform.isMacOS) ...{
    LogicalKeySet(LogicalKeyboardKey.altLeft, LogicalKeyboardKey.arrowLeft):
        const ArrowWordLastIntent(),
    LogicalKeySet(LogicalKeyboardKey.altLeft, LogicalKeyboardKey.arrowRight):
        const ArrowWordNextIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.arrowLeft):
        const ArrowLineBeginIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.arrowRight):
        const ArrowLineEndIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyZ):
        const UndoIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyZ): const RedoIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyA):
        const SelectAllIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyU):
        const UnderlineIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyB):
        const BoldIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyI):
        const ItalicIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyL):
        const LineThroughIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyC):
        const CopyIntent(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyV):
        const PasteIntent(),
  },
  if (!Platform.isMacOS) ...{
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):
        const ArrowWordLastIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):
        const ArrowWordNextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):
        const ArrowLineBeginIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):
        const ArrowLineEndIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
        const UndoIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyZ): const RedoIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
        const SelectAllIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyU):
        const UnderlineIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
        const BoldIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
        const ItalicIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL):
        const LineThroughIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
        const CopyIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
        const PasteIntent(),
  },

  ///TODO:word selection arrow
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):
      const ArrowLeftSelectionIntent(),
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):
      const ArrowRightSelectionIntent(),
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp):
      const ArrowUpSelectionIntent(),
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown):
      const ArrowDownSelectionIntent(),

  const SingleActivator(LogicalKeyboardKey.backspace): const DeleteIntent(),
  const SingleActivator(LogicalKeyboardKey.enter): const NewlineIntent(),

  ///tab
  const SingleActivator(LogicalKeyboardKey.tab): const TabIntent(),
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab):
      const ShiftTabIntent(),
};

final Map<ShortcutActivator, Intent> optionalMenuShortcuts =
    Map.of(editorShortcuts)..addAll(arrowShortcuts);

final Map<ShortcutActivator, Intent> arrowShortcuts = {
  const SingleActivator(LogicalKeyboardKey.arrowUp):
      const OptionalMenuUpArrowIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowDown):
      const OptionalMenuDownArrowIntent(),
  const SingleActivator(LogicalKeyboardKey.enter):
      const OptionalMenuEnterIntent()
};

final Map<ShortcutActivator, Intent> linkMenuShortcuts = {
  const SingleActivator(LogicalKeyboardKey.enter):
      const OptionalMenuEnterIntent()
};

Map<Type, RichEditorControllerAction> shortcutActions = {
  DeleteIntent: (c) => DeleteAction(c),
  UndoIntent: (c) => UndoAction(c),
  RedoIntent: (c) => RedoAction(c),
  NewlineIntent: (c) => NewlineAction(c),
  TabIntent: (c) => TabAction(c),
  ShiftTabIntent: (c) => ShiftTabAction(c),
  LeftArrowIntent: (c) => LeftArrowAction(c),
  RightArrowIntent: (c) => RightArrowAction(c),
  UpArrowIntent: (c) => UpArrowAction(c),
  DownArrowIntent: (c) => DownArrowAction(c),
  ArrowLeftSelectionIntent: (c) => ArrowLeftSelectionAction(c),
  ArrowRightSelectionIntent: (c) => ArrowRightSelectionAction(c),
  ArrowUpSelectionIntent: (c) => ArrowUpSelectionAction(c),
  ArrowDownSelectionIntent: (c) => ArrowDownSelectionAction(c),
  ArrowWordLastIntent: (c) => ArrowWordLastAction(c),
  ArrowWordNextIntent: (c) => ArrowWordNextAction(c),
  ArrowLineBeginIntent: (c) => ArrowLineBeginAction(c),
  ArrowLineEndIntent: (c) => ArrowLineEndAction(c),
  SelectAllIntent: (c) => SelectAllAction(c),
  UnderlineIntent: (c) => UnderlineAction(c),
  BoldIntent: (c) => BoldAction(c),
  ItalicIntent: (c) => ItalicAction(c),
  LineThroughIntent: (c) => LineThroughAction(c),
  CopyIntent: (c) => CopyAction(c),
  PasteIntent: (c) => PasteAction(c),
  OptionalMenuUpArrowIntent: (c) => OptionalMenuUpArrowAction(c),
  OptionalMenuDownArrowIntent: (c) => OptionalMenuDownArrowAction(c),
  OptionalMenuEnterIntent: (c) => OptionalMenuEnterAction(c),
};

Map<Type, Action<Intent>> getActions(EditorContext context) =>
    shortcutActions.map((key, value) => MapEntry(
        key, value.call(ActionOperator(context, () => context.cursor))));

typedef RichEditorControllerAction = Action<Intent> Function(
    ActionOperator context);
