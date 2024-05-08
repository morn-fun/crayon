import 'package:flutter/material.dart';

import '../cursor/basic.dart';
import '../node/basic.dart';
import '../cursor/node_position.dart';
import 'editor_controller.dart';
import 'entry_manager.dart';
import 'input_manager.dart';
import 'listener_collection.dart';

class NodeController {
  final ValueChanged<NodePosition> onEditingPosition;
  final ValueChanged<SelectingPosition> onSelectingPosition;
  final ValueChanged<InputConnectionAttribute> onInputConnectionAttribute;
  final ValueChanged<NodePosition> onPanUpdatePosition;
  final ValueChanged<EditingOffset> onEditingOffsetChanged;
  final ValueChanged<EntryShower> onOverlayEntryShow;
  final ValueGetter<EntryManager> entryManagerGetter;
  final CursorGenerator cursorGenerator;
  final ListenerCollection listeners;
  final NodeGetter nodeGetter;
  final ValueChanged<EditorNode> onNodeChanged;

  NodeController({
    required this.onEditingPosition,
    required this.onSelectingPosition,
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
    onSelectingPosition: (v) {},
    onEditingOffsetChanged: (v) {},
    onInputConnectionAttribute: (v) {},
    onOverlayEntryShow: (s) {},
    nodeGetter: (i) => throw Exception(),
    entryManagerGetter: () => EntryManager(),
    onPanUpdatePosition: (v) {},
    cursorGenerator: (p) => p.toCursor(0),
    listeners: ListenerCollection(),
    onNodeChanged: (n) {},
  );

  void notifyEditingPosition(NodePosition p) => onEditingPosition.call(p);

  void notifySelectingPosition(SelectingPosition p) =>
      onSelectingPosition.call(p);

  void notifyEditingOffset(EditingOffset o) => onEditingOffsetChanged.call(o);

  void notifyPositionWhilePanGesture(NodePosition p) =>
      onPanUpdatePosition.call(p);

  void updateInputConnectionAttribute(InputConnectionAttribute v) =>
      onInputConnectionAttribute.call(v);

  void showOverlayEntry(EntryShower shower) => onOverlayEntryShow.call(shower);

  void updateNode(EditorNode node) => onNodeChanged.call(node);

  EntryManager get entryManager => entryManagerGetter.call();

  EditorNode getNode(int index) => nodeGetter.call(index);

  SingleNodeCursor toCursor(SingleNodePosition p) => cursorGenerator.call(p);

  NodeController copy({
    ValueChanged<NodePosition>? onEditingPosition,
    ValueChanged<SelectingPosition>? onSelectingPosition,
    ValueChanged<InputConnectionAttribute>? onInputConnectionAttribute,
    ValueChanged<NodePosition>? onPanUpdatePosition,
    ValueChanged<EditingOffset>? onEditingOffsetChanged,
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
        onSelectingPosition: onSelectingPosition ?? this.onSelectingPosition,
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
