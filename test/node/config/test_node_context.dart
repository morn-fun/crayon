import 'package:crayon/editor/command/basic.dart';
import 'package:crayon/editor/core/command_invoker.dart';
import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/core/editor_controller.dart';
import 'package:crayon/editor/core/listener_collection.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/node/basic.dart';

class TestNodeContext extends NodeContext{
  @override
  // TODO: implement cursor
  BasicCursor<NodePosition> get cursor => throw UnimplementedError();

  @override
  void execute(BasicCommand command) {
    // TODO: implement execute
  }

  @override
  EditorNode getNode(int index) {
    // TODO: implement getNode
    throw UnimplementedError();
  }

  @override
  Iterable<EditorNode> getRange(int begin, int end) {
    // TODO: implement getRange
    throw UnimplementedError();
  }

  @override
  // TODO: implement listeners
  ListenerCollection get listeners => throw UnimplementedError();

  @override
  // TODO: implement nodes
  List<EditorNode> get nodes => throw UnimplementedError();

  @override
  void onNodeEditing(SingleNodeCursor<NodePosition> cursor, EventType type, {extra}) {
    // TODO: implement onNodeEditing
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
  void updateCursor(BasicCursor<NodePosition> cursor, {bool notify = true}) {
    // TODO: implement updateCursor
  }
}