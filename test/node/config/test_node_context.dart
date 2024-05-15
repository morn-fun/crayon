import 'package:crayon/editor/command/basic.dart';
import 'package:crayon/editor/core/command_invoker.dart';
import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/core/editor_controller.dart';
import 'package:crayon/editor/core/listener_collection.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';

class TestNodeContext extends NodeContext{
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
  void onCursorOffset(CursorOffset o) {
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
  UpdateControllerOperation? replace(Replace data, {bool record = true}) {
    // TODO: implement replace
    throw UnimplementedError();
  }

  @override
  // TODO: implement selectAllCursor
  BasicCursor<NodePosition> get selectAllCursor => throw UnimplementedError();

  @override
  UpdateControllerOperation? update(Update data, {bool record = true}) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  void onNode(EditorNode node, int index) {
    // TODO: implement onNode
  }
}