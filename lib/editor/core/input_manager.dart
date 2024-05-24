import 'dart:io';

import 'package:crayon/editor/extension/node_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../command/basic.dart';
import '../command/modification.dart';
import '../command/replacement.dart';
import '../cursor/basic.dart';
import '../exception/editor_node.dart';
import '../exception/menu.dart';
import '../node/basic.dart';
import 'context.dart';
import 'editor_controller.dart';
import 'logger.dart';

class InputManager with TextInputClient, DeltaTextInputClient {
  final tag = 'InputManager';

  TextInputConnection? _inputConnection;
  InputConnectionAttribute _attribute = InputConnectionAttribute.empty();
  TextEditingValue _localValue = TextEditingValue();
  NodeWithCursor? _typingData;

  final ValueGetter<EditorContext> contextGetter;

  final ValueChanged<BasicCommand> onCommand;
  final ValueChanged<NodesOperator> onOptionalMenu;
  final VoidCallback focusCall;

  EditorContext get editorContext => contextGetter.call();

  RichEditorController get controller => editorContext.controller;

  BasicCursor get cursor => controller.cursor;

  InputManager(
      {required this.contextGetter,
      required this.onCommand,
      required this.onOptionalMenu,
      required this.focusCall});

  @override
  void connectionClosed() {
    logger.i('$tag, connectionClosed');
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  TextEditingValue? get currentTextEditingValue => _localValue;

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
    TextEditingValue newValue = _localValue;
    for (var delta in textEditingDeltas) {
      newValue = delta.apply(newValue);
    }
    _localValue = newValue;
    if (cursor is NoneCursor) return;
    logger.i('updateEditingValueWithDeltas, localValue：$_localValue');
    BasicCommand? command = _buildCommand();
    final composing = _localValue.composing;

    ///FIXME:in MacOS, there is an inconsistent result here
    final specialJudgement =
        Platform.isMacOS && composing == TextRange(start: 0, end: 0);
    if (composing == TextRange.empty || specialJudgement) {
      controller.updateStatus(ControllerStatus.idle);
      restartInput();
    } else {
      controller.updateStatus(ControllerStatus.typing);
    }
    if (command != null) onCommand.call(command);
  }

  BasicCommand? _buildCommand() {
    final c = _typingData?.cursor ?? cursor;
    if (c is EditingCursor) {
      final node = _typingData?.node ?? controller.getNode(c.index);
      _typingData ??= NodeWithCursor(node, c);
      try {
        final newOne = node.onEdit(EditingData(
            c, EventType.typing, editorContext,
            extras: _localValue));
        return ModifyNode(newOne);
      } on TypingToChangeNodeException catch (e) {
        final index = c.index;
        return ReplaceNode(
            Replace(index, index + 1, [e.current.node], e.current.cursor));
      } on TypingRequiredOptionalMenuException catch (e) {
        onOptionalMenu.call(e.context);
        return ModifyNode(e.nodeWithCursor);
      } on NodeUnsupportedException catch (e) {
        logger.e('error while typing: ${e.message}');
      }
    } else if (c is SelectingNodeCursor) {
      try {
        final r = controller
            .getNode(c.index)
            .onSelect(SelectingData(c, EventType.delete, editorContext));
        if (r.cursor is! EditingCursor) return null;
        _typingData ??= r;
        final newOne = r.node.onEdit(EditingData(
            r.cursor as EditingCursor, EventType.typing, editorContext,
            extras: _localValue));
        return ModifyNode(newOne);
      } on TypingRequiredOptionalMenuException catch (e) {
        onOptionalMenu.call(e.context);
        return ModifyNode(e.nodeWithCursor);
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    } else if (c is SelectingNodesCursor) {
      final leftCursor = c.left;
      final rightCursor = c.right;
      final leftNode = controller.getNode(leftCursor.index);
      final rightNode = controller.getNode(rightCursor.index);
      final left = leftNode.frontPartNode(leftCursor.position);
      final right =
          rightNode.rearPartNode(rightCursor.position, newId: randomNodeId);
      final mergeNode = left.merge(right);
      List<EditorNode> listNeedRefreshDepth = editorContext
          .listNeedRefreshDepth(rightCursor.index, mergeNode.depth);
      final newCursor = EditingCursor(leftCursor.index, left.endPosition);
      _typingData ??= NodeWithCursor(mergeNode, newCursor);
      try {
        final newOne = mergeNode.onEdit(EditingData(
            newCursor, EventType.typing, editorContext,
            extras: _localValue));
        return ReplaceNode(Replace(
            leftCursor.index,
            rightCursor.index + 1 + listNeedRefreshDepth.length,
            [newOne.node, ...listNeedRefreshDepth],
            newOne.cursor));
      } on TypingRequiredOptionalMenuException catch (e) {
        onOptionalMenu.call(e.context);
        final newOne = e.nodeWithCursor;
        return ReplaceNode(Replace(
            leftCursor.index,
            rightCursor.index + 1 + listNeedRefreshDepth.length,
            [newOne.node, ...listNeedRefreshDepth],
            newOne.cursor));
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    }
    return null;
  }

  void restartInput() {
    logger.i('$tag, restartInput');
    _typingData = null;
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
