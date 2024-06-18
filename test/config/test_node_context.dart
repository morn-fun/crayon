import 'package:crayon/editor/command/basic.dart';
import 'package:crayon/editor/core/command_invoker.dart';
import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/core/editor_controller.dart';
import 'package:crayon/editor/core/listener_collection.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';

class TestNodeContext extends NodesOperator {
  @override
  // TODO: implement cursor
  BasicCursor<NodePosition> get cursor => throw UnimplementedError();

  @override
  void execute(BasicCommand command) {
    // TODO: implement execute
  }

  @override
  EditorNode getNode(int index) => RichTextNode.from([]);

  @override
  Iterable<EditorNode> getRange(int begin, int end) {
    // TODO: implement getRange
    throw UnimplementedError();
  }

  @override
  // TODO: implement listeners
  ListenerCollection get listeners => ListenerCollection();

  @override
  // TODO: implement nodes
  List<EditorNode> get nodes => throw UnimplementedError();

  @override
  void onCursorOffset(EditingOffset o) {
    // TODO: implement onCursorOffset
  }

  @override
  void onCursor(BasicCursor<NodePosition> cursor) {
    // TODO: implement onCursor
  }

  @override
  void onPanUpdate(EditingCursor<NodePosition> cursor) {
    // TODO: implement onPanUpdate
  }

  @override
  // TODO: implement selectAllCursor
  BasicCursor<NodePosition> get selectAllCursor => throw UnimplementedError();


  @override
  void onNode(EditorNode node, int index) {
    // TODO: implement onNode
  }

  @override
  NodesOperator newOperator(
          List<EditorNode> nodes, BasicCursor<NodePosition> cursor) =>
      this;

  @override
  UpdateControllerOperation? onOperation(UpdateControllerOperation operation, {bool record = true}) {
    // TODO: implement onOperation
    throw UnimplementedError();
  }
}
