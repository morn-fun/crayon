import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pre_editor/editor/node/position_data.dart';

import '../command/basic_command.dart';
import '../command/modification.dart';
import '../command/selecting_nodes/replace.dart';
import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import '../shortcuts/shortcuts.dart';
import 'controller.dart';
import 'logger.dart';

class InputManager with TextInputClient, DeltaTextInputClient {
  final tag = 'InputManager';

  TextInputConnection? _inputConnection;
  InputConnectionAttribute _attribute = InputConnectionAttribute.empty();

  final RichEditorController controller;
  final ShortcutManager shortcutManager;

  final ValueChanged<BasicCommand> onCommand;
  final VoidCallback _focusCall;

  BasicCursor get cursor => controller.cursor;

  InputManager(
      this.controller, this.shortcutManager, this.onCommand, this._focusCall);

  bool _typing = false;

  bool get typing => _typing;

  @override
  void connectionClosed() {
    logger.i('$tag, connectionClosed');
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  TextEditingValue? get currentTextEditingValue => null;

  @override
  void performAction(TextInputAction action) {
    logger.i('$tag, performAction:$action');
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    logger.i('$tag, performPrivateCommand  action: $action, data: $data}');
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    logger.i('$tag, showAutocorrectionPromptRect  start: $start, end: $end}');
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    logger.i('$tag, updateEditingValue value: $value');
    _inputConnection?.setEditingState(value);
    _inputConnection?.show();
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    logger.i('$tag, updateFloatingCursor point: $point');
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    final c = cursor;
    if (c is NoneCursor) return;
    final last = textEditingDeltas.last;
    logger.i('updateEditingValueWithDeltas:$textEditingDeltas');
    final noComposing = last.composing == TextRange.empty;
    final isEmptyComposing =
        last.composing == const TextRange(start: 0, end: 0);
    BasicCommand? command = _buildCommand(last);
    if ((last is TextEditingDeltaNonTextUpdate) ||
        (last is TextEditingDeltaReplacement && noComposing) ||
        (last is TextEditingDeltaInsertion && noComposing) ||
        (last is TextEditingDeltaDeletion && isEmptyComposing)) {
      _typing = false;
      shortcutManager.shortcuts = editorShortcuts;
      restartInput();
    } else {
      shortcutManager.shortcuts = {};
      _typing = true;
    }
    if (command != null) onCommand.call(command);
  }

  BasicCommand? _buildCommand(TextEditingDelta delta) {
    final c = cursor;
    if (c is EditingCursor) {
      final node = controller.getNode(c.index);
      final newOne =
          node.onEdit(EditingData(c.position, EventType.typing, extras: delta));
      return ModifyNode(newOne.toCursor(c.index), newOne.node);
    } else if (c is SelectingNodeCursor) {
      final node = controller.getNode(c.index);
      final newOne = node.onSelect(SelectingData(
          SelectingPosition(c.begin, c.end), EventType.typing,
          extras: delta));
      return ModifyNode(newOne.toCursor(c.index), newOne.node);
    } else if (c is SelectingNodesCursor) {
      return ReplaceSelectingNodes(c, EventType.typing, delta);
    }
    return null;
  }

  void restartInput() {
    logger.i('$tag, restartInput');
    stopInput();
    startInput();
  }

  void requestFocus() {
    logger.i('$tag, requestFocus');
    _focusCall.call();
  }

  bool get attached => _inputConnection?.attached ?? false;

  void startInput() {
    if (!attached) {
      _inputConnection = TextInput.attach(
        this,
        const TextInputConfiguration(
          inputAction: TextInputAction.newline,
          inputType: TextInputType.multiline,
          enableDeltaModel: true,
        ),
      )
        ..setEditingState(const TextEditingValue())
        ..setEditableSizeAndTransform(_attribute.size, _attribute.transform)
        ..setCaretRect(_attribute.caretRect)
        ..setComposingRect(_attribute.caretRect)
        ..show();
    } else {
      _inputConnection!.show();
    }
  }

  void stopInput() {
    _inputConnection?.close();
    _inputConnection = null;
  }

  void updateInputConnectionAttribute(InputConnectionAttribute attribute) {
    _attribute = attribute;
    _inputConnection
      ?..setCaretRect(_attribute.caretRect)
      ..setComposingRect(_attribute.caretRect)
      ..setEditableSizeAndTransform(_attribute.size, _attribute.transform)
      ..show();
  }

  void dispose() {
    logger.i('$tag, dispose');
    _inputConnection?.close();
    _inputConnection = null;
    _attribute = InputConnectionAttribute.empty();
  }
}

class InputConnectionAttribute {
  final Rect caretRect;
  final Matrix4 transform;
  final Size size;

  InputConnectionAttribute(this.caretRect, this.transform, this.size);

  InputConnectionAttribute.empty()
      : caretRect = Rect.zero,
        transform = Matrix4.zero(),
        size = Size.zero;

  @override
  String toString() {
    return 'InputConnectionAttribute{caretRect: $caretRect,  size: $size}';
  }
}
