import 'dart:io';

import 'package:crayon/editor/shortcuts/arrows/selection_arrow.dart';
import 'package:crayon/editor/shortcuts/arrows/selection_word_arrow.dart';
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
  const SingleActivator(LogicalKeyboardKey.arrowLeft): const ArrowLeftIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowRight):
      const ArrowRightIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowUp): const ArrowUpIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowDown): const ArrowDownIntent(),

  if (Platform.isMacOS) ...{
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowLeft):
        const ArrowLineBeginIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowRight):
        const ArrowLineEndIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ):
        const UndoIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyZ): const RedoIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyA):
        const SelectAllIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyU):
        const UnderlineIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyB):
        const BoldIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyI):
        const ItalicIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyL):
        const LineThroughIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC):
        const CopyIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyV):
        const PasteIntent(),
  },
  if (!Platform.isMacOS) ...{
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

  LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft):
      const ArrowWordLastIntent(),
  LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight):
      const ArrowWordNextIntent(),
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.alt,
      LogicalKeyboardKey.arrowLeft): const ArrowSelectionWordLastIntent(),
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.alt,
      LogicalKeyboardKey.arrowRight): const ArrowSelectionWordNextIntent(),
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):
      const ArrowSelectionLeftIntent(),
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):
      const ArrowSelectionRightIntent(),
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp):
      const ArrowSelectionUpIntent(),
  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown):
      const ArrowSelectionDownIntent(),

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
  ArrowLeftIntent: (c) => ArrowLeftAction(c),
  ArrowRightIntent: (c) => ArrowRightAction(c),
  ArrowUpIntent: (c) => ArrowUpAction(c),
  ArrowDownIntent: (c) => ArrowDownAction(c),
  ArrowSelectionLeftIntent: (c) => ArrowSelectionLeftAction(c),
  ArrowSelectionRightIntent: (c) => ArrowSelectionRightAction(c),
  ArrowSelectionUpIntent: (c) => ArrowSelectionUpAction(c),
  ArrowSelectionDownIntent: (c) => ArrowSelectionDownAction(c),
  ArrowSelectionWordLastIntent: (c) => ArrowSelectionWordLastAction(c),
  ArrowSelectionWordNextIntent: (c) => ArrowSelectionWordNextAction(c),
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
        key, value.call(ActionOperator(context, () => context.controller.panEndCursor))));

typedef RichEditorControllerAction = Action<Intent> Function(
    ActionOperator context);
