import 'package:flutter/services.dart';

import '../command/basic_command.dart';
import '../cursor/basic_cursor.dart';
import 'command_generator.dart';
import 'controller.dart';
import 'logger.dart';

class InputManager with TextInputClient, DeltaTextInputClient {
  final _tag = 'InputManager';

  TextInputConnection? _inputConnection;
  InputConnectionAttribute _attribute = InputConnectionAttribute.empty();

  final RichEditorController controller;

  final ValueChanged<BasicCommand> onCommand;

  BasicCursor get cursor => controller.cursor;

  InputManager(this.controller, this.onCommand);

  bool _typing = false;

  bool get typing => _typing;

  @override
  void connectionClosed() {
    logger.i('$_tag, connectionClosed');
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  TextEditingValue? get currentTextEditingValue => null;

  @override
  void performAction(TextInputAction action) {
    logger.i('$_tag, performAction:$action');
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    logger.i('$_tag, performPrivateCommand  action: $action, data: $data}');
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    logger.i('$_tag, showAutocorrectionPromptRect  start: $start, end: $end}');
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    logger.i('$_tag, updateEditingValue value: $value');
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    logger.i('$_tag, updateFloatingCursor point: $point');
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    if (cursor is NoneCursor) return;
    final last = textEditingDeltas.last;
    logger.i('updateEditingValueWithDeltas:$last');
    final noComposing = last.composing == TextRange.empty;
    BasicCommand? command = generateCommand(last, controller);
    if ((last is TextEditingDeltaNonTextUpdate) ||
        (last is TextEditingDeltaReplacement && noComposing) ||
        (last is TextEditingDeltaInsertion && noComposing)) {
      _typing = false;
      restartInput();
    } else {
      _typing = true;
    }
    if (command != null) onCommand.call(command);
  }

  void restartInput() {
    stopInput();
    startInput();
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
    logger.i('$_tag, dispose');
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
