import 'package:flutter/services.dart';

import '../command/basic.dart';
import '../command/modify.dart';
import '../command/replace.dart';
import '../command/selecting/replace.dart';
import '../cursor/basic.dart';
import '../exception/editor_node.dart';
import '../node/basic.dart';
import '../cursor/node_position.dart';
import 'editor_controller.dart';
import 'entry_manager.dart';
import 'logger.dart';

class InputManager with TextInputClient, DeltaTextInputClient {
  final tag = 'InputManager';

  TextInputConnection? _inputConnection;
  InputConnectionAttribute _attribute = InputConnectionAttribute.empty();

  final RichEditorController controller;

  final ValueChanged<BasicCommand> onCommand;
  final ValueChanged<EntryStatus> onEntryStatus;
  final VoidCallback focusCall;

  BasicCursor get cursor => controller.cursor;

  InputManager(
      {required this.controller,
      required this.onCommand,
      required this.onEntryStatus,
      required this.focusCall});

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
    // logger.i('updateEditingValueWithDeltas:$textEditingDeltas');
    final noComposing = last.composing == TextRange.empty;
    final isZeroComposing = last.composing == const TextRange(start: 0, end: 0);
    BasicCommand? command = _buildCommand(last);

    if ((last is TextEditingDeltaNonTextUpdate &&
            (noComposing || isZeroComposing)) ||
        (last is TextEditingDeltaReplacement && noComposing) ||
        (last is TextEditingDeltaInsertion && noComposing) ||
        (last is TextEditingDeltaDeletion && isZeroComposing)) {
      controller.updateStatus(ControllerStatus.idle);
      restartInput();
    } else {
      controller.updateStatus(ControllerStatus.typing);
    }
    if (command != null) onCommand.call(command);
  }

  BasicCommand? _buildCommand(TextEditingDelta delta) {
    final c = cursor;
    if (c is EditingCursor) {
      final node = controller.getNode(c.index);
      try {
        final newOne = node
            .onEdit(EditingData(c.position, EventType.typing, extras: delta));
        return ModifyNode(newOne.toCursor(c.index), newOne.node);
      } on TypingToChangeNodeException catch (e) {
        final index = c.index;
        return ReplaceNode(Replace(
            index, index + 1, [e.current.node], e.current.toCursor(c.index)));
      } on TypingRequiredOptionalMenuException catch (e) {
        onEntryStatus.call(EntryStatus.readyToShowingOptionalMenu);
        return ModifyNode(e.nodeWithPosition.position.toCursor(c.index),
            e.nodeWithPosition.node);
      }
    } else if (c is SelectingNodeCursor) {
      final node = controller.getNode(c.index);
      try {
        final newOne = node.onSelect(SelectingData(
            SelectingPosition(c.begin, c.end), EventType.typing,
            extras: delta));
        return ModifyNode(newOne.toCursor(c.index), newOne.node);
      } on TypingToChangeNodeException catch (e) {
        final index = c.index;
        return ReplaceNode(Replace(
            index, index + 1, [e.current.node], e.current.toCursor(c.index)));
      } on TypingRequiredOptionalMenuException catch (e) {
        onEntryStatus.call(EntryStatus.readyToShowingOptionalMenu);
        return ModifyNode(e.nodeWithPosition.position.toCursor(c.index),
            e.nodeWithPosition.node);
      }
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
    focusCall.call();
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
