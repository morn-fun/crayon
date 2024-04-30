import 'package:flutter/material.dart';

import '../core/context.dart';
import '../widget/menu/optional.dart';

class OptionalMenuUpArrowIntent extends Intent {
  const OptionalMenuUpArrowIntent();
}

class OptionalMenuDownArrowIntent extends Intent {
  const OptionalMenuDownArrowIntent();
}

class OptionalMenuEnterIntent extends Intent {
  const OptionalMenuEnterIntent();
}

class OptionalMenuUpArrowAction
    extends ContextAction<OptionalMenuUpArrowIntent> {
  final EditorContext editorContext;

  OptionalMenuUpArrowAction(this.editorContext);

  @override
  void invoke(OptionalMenuUpArrowIntent intent, [BuildContext? context]) {
    final listeners = editorContext.listeners;
    listeners.notifyOptionalMenu(OptionalSelectedType.last);
  }
}

class OptionalMenuDownArrowAction
    extends ContextAction<OptionalMenuDownArrowIntent> {
  final EditorContext editorContext;

  OptionalMenuDownArrowAction(this.editorContext);

  @override
  void invoke(OptionalMenuDownArrowIntent intent, [BuildContext? context]) {
    final listeners = editorContext.listeners;
    listeners.notifyOptionalMenu(OptionalSelectedType.next);
  }
}

class OptionalMenuEnterAction extends ContextAction<OptionalMenuEnterIntent> {
  final EditorContext editorContext;

  OptionalMenuEnterAction(this.editorContext);

  @override
  void invoke(OptionalMenuEnterIntent intent, [BuildContext? context]) {
    final listeners = editorContext.listeners;
    listeners.notifyOptionalMenu(OptionalSelectedType.current);
  }
}
