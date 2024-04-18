import 'package:flutter/material.dart';

import '../cursor/basic_cursor.dart';
import '../node/basic_node.dart';
import '../node/position_data.dart';
import 'entry_manager.dart';
import 'input_manager.dart';
import 'listener_collection.dart';

class NodeController {
  final ValueChanged<NodePosition> onEditingPosition;
  final ValueChanged<InputConnectionAttribute> onInputConnectionAttribute;
  final ValueChanged<NodePosition> onPanUpdatePosition;
  final ValueChanged<double> onEditingOffsetChanged;
  final ValueChanged<EntryShower> onOverlayEntryShow;
  final ValueGetter<EntryManager> entryManagerGetter;
  final CursorGenerator cursorGenerator;
  final ListenerCollection listeners;
  final NodeGetter nodeGetter;

  NodeController({
    required this.onEditingPosition,
    required this.onInputConnectionAttribute,
    required this.onOverlayEntryShow,
    required this.onPanUpdatePosition,
    required this.entryManagerGetter,
    required this.listeners,
    required this.cursorGenerator,
    required this.onEditingOffsetChanged,
    required this.nodeGetter,
  });

  void notifyEditingPosition(NodePosition position) =>
      onEditingPosition.call(position);

  void notifyEditingOffset(double y) => onEditingOffsetChanged.call(y);

  void notifyPositionWhilePanGesture(NodePosition p) =>
      onPanUpdatePosition.call(p);

  void updateInputConnectionAttribute(InputConnectionAttribute v) =>
      onInputConnectionAttribute.call(v);

  void showOverlayEntry(EntryShower shower) => onOverlayEntryShow.call(shower);

  EntryStatus get entryStatus => entryManager.status;

  EntryManager get entryManager => entryManagerGetter.call();

  EditorNode getNode(int index) => nodeGetter.call(index);

  void updateEntryStatus(EntryStatus status) =>
      entryManager.updateStatus(status);

  SingleNodeCursor toCursor(SingleNodePosition p) => cursorGenerator.call(p);
}


typedef NodeGetter = EditorNode Function(int index);

typedef CursorGenerator = SingleNodeCursor Function(SingleNodePosition p);
