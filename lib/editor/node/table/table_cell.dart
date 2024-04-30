import 'dart:collection';
import 'package:crayon/editor/core/listener_collection.dart';
import 'package:flutter/cupertino.dart';

import '../../../../editor/extension/unmodifiable.dart';
import '../../../../editor/node/rich_text/rich_text.dart';
import '../../../../editor/command/basic.dart';
import '../../../../editor/core/command_invoker.dart';
import '../../../../editor/core/editor_controller.dart';
import '../../../../editor/shortcuts/arrows/arrows.dart';
import '../../command/modification.dart';
import '../../core/context.dart';
import '../../core/copier.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../cursor/node_position.dart';
import '../../cursor/table_cell.dart';
import '../basic.dart';

class TableCell {
  final UnmodifiableListView<EditorNode> nodes;

  TableCell(List<EditorNode> nodes) : nodes = _initNodes(nodes);

  TableCell.empty() : nodes = _initNodes([]);

  static UnmodifiableListView<EditorNode> _initNodes(List<EditorNode> nodes) {
    if (nodes.isEmpty) return UnmodifiableListView([RichTextNode.from([])]);
    return UnmodifiableListView(nodes);
  }

  int get length => nodes.length;

  EditorNode get last => nodes.last;

  EditorNode get first => nodes.first;

  TableCellPosition get beginPosition =>
      TableCellPosition(0, first.beginPosition, atEdge: true);

  TableCellPosition get endPosition =>
      TableCellPosition(length - 1, last.endPosition, atEdge: true);

  EditorNode getNode(int index) => nodes[index];

  TableCell clear() => TableCell([RichTextNode.from([])]);

  bool isBegin(TableCellPosition p) {
    if (!p.atEdge) return false;
    if (p.index != 0) return false;
    if (p.position != first.beginPosition) return false;
    return true;
  }

  bool isEnd(TableCellPosition p) {
    if (!p.atEdge) return false;
    if (p.index != length - 1) return false;
    if (p.position != last.endPosition) return false;
    return true;
  }

  bool wholeSelected(TableCellPosition begin, TableCellPosition end){
    final left = begin.isLowerThan(end) ? begin : end;
    final right = begin.isLowerThan(end) ? end : begin;
    return isBegin(left) && isEnd(right);
  }

  TableCell update(int index, ValueCopier<EditorNode> copier) =>
      TableCell(nodes.update(index, copier));

  TableCell updateMore(
          int begin, int end, ValueCopier<List<EditorNode>> copier) =>
      TableCell(nodes.updateMore(begin, end, copier));

  TableCell replaceMore(int begin, int end, Iterable<EditorNode> newNodes) =>
      TableCell(nodes.replaceMore(begin, end, newNodes));

  List<EditorNode> getNodes(TableCellPosition begin, TableCellPosition end) {
    final left = begin.isLowerThan(end) ? begin : end;
    final right = begin.isLowerThan(end) ? end : begin;
    final leftNode = getNode(left.index);
    final rightNode = getNode(right.index);
    if (left.index == right.index) {
      return [leftNode.getFromPosition(left.position, right.position)];
    } else {
      final newLeftNode =
          leftNode.rearPartNode(left.position, newId: randomNodeId);
      final newRightNode =
          rightNode.frontPartNode(right.position, newId: randomNodeId);
      return [
        newLeftNode,
        ...nodes.getRange(left.index + 1, right.index),
        newRightNode
      ];
    }
  }

  List<Map<String, dynamic>> toJson() => nodes.map((e) => e.toJson()).toList();

  String get text => nodes.map((e) => e.text).join('\n');

  TableCellNodeContext buildContext({
    required BasicCursor cursor,
    required ListenerCollection listeners,
    required ValueChanged<Replace> onReplace,
    required ValueChanged<Update> onUpdate,
    required ValueChanged<BasicCursor> onCursor,
  }) =>
      TableCellNodeContext(
          cursor, this, listeners, onReplace, onUpdate, onCursor);
}

class TableCellNodeContext extends NodeContext {
  @override
  final BasicCursor cursor;
  final TableCell cell;
  @override
  final ListenerCollection listeners;
  final ValueChanged<Replace> onReplace;
  final ValueChanged<Update> onUpdate;
  final ValueChanged<BasicCursor> onCursor;

  TableCellNodeContext(
    this.cursor,
    this.cell,
    this.listeners,
    this.onReplace,
    this.onUpdate,
    this.onCursor,
  );

  final tag = 'TableCellNodeContext';

  @override
  void execute(BasicCommand command) {
    try {
      logger.i('$tag, execute 【$command】');
      command.run(this);
    } catch (e) {
      logger.e('execute 【$command】error:${e}');
    }
  }

  @override
  EditorNode getNode(int index) => cell.getNode(index);

  @override
  Iterable<EditorNode> getRange(int begin, int end) =>
      cell.nodes.getRange(begin, end);

  @override
  void hideMenu() {}

  @override
  int get nodeLength => cell.length;

  @override
  // TODO: implement nodes
  List<EditorNode> get nodes => cell.nodes;

  @override
  void onNodeEditing(SingleNodeCursor<NodePosition> cursor, EventType type,
      {dynamic extra}) {
    if (cursor is EditingCursor) {
      final r = getNode(cursor.index)
          .onEdit(EditingData(cursor.position, type, listeners, extras: extra));
      execute(ModifyNode(r.position.toCursor(cursor.index), r.node));
    } else if (cursor is SelectingNodeCursor) {
      final r = getNode(cursor.index).onSelect(SelectingData(
          SelectingPosition(cursor.begin, cursor.end), type, listeners,
          extras: extra));
      execute(ModifyNode(r.position.toCursor(cursor.index), r.node));
    }
  }

  @override
  UpdateControllerOperation? replace(Replace data, {bool record = true}) {
    onReplace.call(data);
    return null;
  }

  @override
  SelectingNodesCursor<NodePosition> get selectAllCursor =>
      SelectingNodesCursor(IndexWithPosition(0, cell.first.beginPosition),
          IndexWithPosition(nodeLength - 1, cell.last.endPosition));

  @override
  UpdateControllerOperation? update(Update data, {bool record = true}) {
    onUpdate.call(data);
    return null;
  }

  @override
  void updateCursor(BasicCursor cursor, {bool notify = true}) =>
      onCursor.call(cursor);
}
