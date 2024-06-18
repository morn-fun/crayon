import '../core/command_invoker.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import '../cursor/basic.dart';
import '../node/rich_text/rich_text.dart';
import 'basic.dart';

class ReplaceNode implements BasicCommand {
  final Replace replace;
  final bool record;

  ReplaceNode(this.replace, {this.record = true});

  @override
  UpdateControllerOperation? run(NodesOperator operator) {
    return operator.onOperation(replace, record: record);
  }

  @override
  String toString() {
    return 'ReplaceNode{replace: $replace, record: $record}';
  }
}

class AddRichTextNode implements BasicCommand {
  final RichTextNode node;

  AddRichTextNode(this.node);

  @override
  UpdateControllerOperation? run(NodesOperator operator) {
    final index = operator.nodes.length - 1;
    final last = operator.nodes.last;
    return operator.onOperation(Replace(index, index + 1, [last, node],
        EditingCursor(index + 1, node.endPosition)));
  }

  @override
  String toString() {
    return 'AddRichTextNode{node: $node}';
  }
}
