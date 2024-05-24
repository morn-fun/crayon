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
  final ActionContext ac;

  NodesOperator get nodeContext => ac.context;

  OptionalMenuUpArrowAction(this.ac);

  @override
  void invoke(OptionalMenuUpArrowIntent intent, [BuildContext? context]) {
    final listeners = nodeContext.listeners;
    listeners.notifyOptionalMenu(OptionalSelectedType.last);
  }
}

class OptionalMenuDownArrowAction
    extends ContextAction<OptionalMenuDownArrowIntent> {
  final ActionContext ac;

  NodesOperator get nodeContext => ac.context;

  OptionalMenuDownArrowAction(this.ac);

  @override
  void invoke(OptionalMenuDownArrowIntent intent, [BuildContext? context]) {
    final listeners = nodeContext.listeners;
    listeners.notifyOptionalMenu(OptionalSelectedType.next);
  }
}

class OptionalMenuEnterAction extends ContextAction<OptionalMenuEnterIntent> {
  final ActionContext ac;

  NodesOperator get nodeContext => ac.context;

  OptionalMenuEnterAction(this.ac);

  @override
  void invoke(OptionalMenuEnterIntent intent, [BuildContext? context]) {
    final listeners = nodeContext.listeners;
    listeners.notifyOptionalMenu(OptionalSelectedType.current);
  }
}
