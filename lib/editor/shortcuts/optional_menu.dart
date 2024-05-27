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
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  OptionalMenuUpArrowAction(this.ac);

  @override
  void invoke(OptionalMenuUpArrowIntent intent, [BuildContext? context]) {
    final listeners = operator.listeners;
    listeners.notifyOptionalMenu(OptionalSelectedType.last);
  }
}

class OptionalMenuDownArrowAction
    extends ContextAction<OptionalMenuDownArrowIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  OptionalMenuDownArrowAction(this.ac);

  @override
  void invoke(OptionalMenuDownArrowIntent intent, [BuildContext? context]) {
    final listeners = operator.listeners;
    listeners.notifyOptionalMenu(OptionalSelectedType.next);
  }
}

class OptionalMenuEnterAction extends ContextAction<OptionalMenuEnterIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  OptionalMenuEnterAction(this.ac);

  @override
  void invoke(OptionalMenuEnterIntent intent, [BuildContext? context]) {
    final listeners = operator.listeners;
    listeners.notifyOptionalMenu(OptionalSelectedType.current);
  }
}
