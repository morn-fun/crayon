import 'package:flutter/material.dart';

import '../cursor/basic.dart';
import '../node/basic.dart';
import '../cursor/node_position.dart';
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
  final ValueChanged<EditorNode> onNodeChanged;

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
    required this.onNodeChanged,
  });

  static NodeController empty = NodeController(
    onEditingPosition: (v) {},
    onEditingOffsetChanged: (v) {},
    onInputConnectionAttribute: (v) {},
    onOverlayEntryShow: (s) {},
    nodeGetter: (i) => throw Exception(),
    entryManagerGetter: () => EntryManager((status) => null),
    onPanUpdatePosition: (v) {},
    cursorGenerator: (p) => p.toCursor(0),
    listeners: ListenerCollection(),
    onNodeChanged: (n) {},
  );

  void notifyEditingPosition(NodePosition position) =>
      onEditingPosition.call(position);

  void notifyEditingOffset(double y) => onEditingOffsetChanged.call(y);

  void notifyPositionWhilePanGesture(NodePosition p) =>
      onPanUpdatePosition.call(p);

  void updateInputConnectionAttribute(InputConnectionAttribute v) =>
      onInputConnectionAttribute.call(v);

  void showOverlayEntry(EntryShower shower) => onOverlayEntryShow.call(shower);

  void updateNode(EditorNode node) => onNodeChanged.call(node);

  EntryStatus get entryStatus => entryManager.status;

  EntryManager get entryManager => entryManagerGetter.call();

  EditorNode getNode(int index) => nodeGetter.call(index);

  void updateEntryStatus(EntryStatus status) =>
      entryManager.updateStatus(status);

  SingleNodeCursor toCursor(SingleNodePosition p) => cursorGenerator.call(p);

  NodeController copy({
    ValueChanged<NodePosition>? onEditingPosition,
    ValueChanged<InputConnectionAttribute>? onInputConnectionAttribute,
    ValueChanged<NodePosition>? onPanUpdatePosition,
    ValueChanged<double>? onEditingOffsetChanged,
    ValueChanged<EntryShower>? onOverlayEntryShow,
    ValueGetter<EntryManager>? entryManagerGetter,
    CursorGenerator? cursorGenerator,
    ListenerCollection? listeners,
    NodeGetter? nodeGetter,
    ValueChanged<EditorNode>? onNodeChanged,
    VoidCallback? focusCallback,
  }) =>
      NodeController(
        onEditingPosition: onEditingPosition ?? this.onEditingPosition,
        onInputConnectionAttribute:
            onInputConnectionAttribute ?? this.onInputConnectionAttribute,
        onOverlayEntryShow: onOverlayEntryShow ?? this.onOverlayEntryShow,
        onPanUpdatePosition: onPanUpdatePosition ?? this.onPanUpdatePosition,
        entryManagerGetter: entryManagerGetter ?? this.entryManagerGetter,
        listeners: listeners ?? this.listeners,
        cursorGenerator: cursorGenerator ?? this.cursorGenerator,
        onEditingOffsetChanged:
            onEditingOffsetChanged ?? this.onEditingOffsetChanged,
        nodeGetter: nodeGetter ?? this.nodeGetter,
        onNodeChanged: onNodeChanged ?? this.onNodeChanged,
      );
}

typedef NodeGetter = EditorNode Function(int index);

typedef CursorGenerator = SingleNodeCursor Function(SingleNodePosition p);
