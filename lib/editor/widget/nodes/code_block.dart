import 'dart:collection';
import 'dart:math';

import 'package:crayon/editor/widget/editor/shared_node_context_widget.dart';
import 'package:flutter/material.dart';
import 'package:highlight/languages/all.dart';
import '../../../../editor/extension/render_box.dart';
import '../../core/context.dart';
import '../../../editor/cursor/basic.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../../cursor/code_block.dart';
import '../../exception/editor_node.dart';
import '../../node/code_block/code_block.dart';
import '../../shortcuts/arrows/arrows.dart';
import '../../../editor/core/editor_controller.dart';
import '../menu/code_selector.dart';
import 'code_block_line.dart';

class CodeBlock extends StatefulWidget {
  const CodeBlock(
    this.operator,
    this.node,
    this.param, {
    super.key,
    this.maxLineHeight = 20,
  });

  final NodesOperator operator;
  final CodeBlockNode node;
  final NodeBuildParam param;
  final double maxLineHeight;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  final tag = 'CodeBlock';

  final key = GlobalKey();

  CodeBlockNode get node => widget.node;

  NodesOperator get operator => widget.operator;

  ListenerCollection get listeners => operator.listeners;

  ListenerCollection localListeners = ListenerCollection();

  List<String> get codes => node.codes;

  Offset lastEditOffset = Offset.zero;

  SingleNodeCursor? get nodeCursor => widget.param.cursor;

  int get widgetIndex => widget.param.index;

  double get lineHeight => widget.maxLineHeight;

  String get nodeId => node.id;

  final padding = EdgeInsets.all(24);
  final margin = EdgeInsets.symmetric(vertical: 8);

  final hoveredNotifier = ValueNotifier(false);

  final languageController = OverlayPortalController();

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  @override
  void initState() {
    super.initState();
    listeners.addArrowDelegate(nodeId, onArrowAccept);
    listeners.addGestureListener(nodeId, onGesture);
  }

  @override
  void didUpdateWidget(covariant CodeBlock oldWidget) {
    final oldListeners = oldWidget.operator.listeners;
    if (oldListeners.hashCode != listeners.hashCode) {
      oldListeners.removeGestureListener(nodeId, onGesture);
      oldListeners.removeArrowDelegate(nodeId, onArrowAccept);
      listeners.addGestureListener(nodeId, onGesture);
      listeners.addArrowDelegate(nodeId, onArrowAccept);
      logger.i(
          '${node.runtimeType} onListenerChanged:${oldListeners.hashCode},  newListener:${listeners.hashCode}');
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    listeners.removeArrowDelegate(nodeId, onArrowAccept);
    listeners.removeGestureListener(nodeId, onGesture);
    localListeners.dispose();
    hoveredNotifier.dispose();
    super.dispose();
  }

  bool onGesture(GestureState s) {
    final box = renderBox;
    if (box == null) return false;
    bool contains = box.containsOffset(s.globalOffset);
    if (!contains) return false;
    final localY = box.globalToLocal(s.globalOffset).dy - margin.top - padding.top;
    final index = localY ~/ lineHeight;
    final notifyId = '$nodeId$index';
    if (s is TapGestureState) {
      localListeners.notifyGesture(notifyId, s);
      return true;
    } else if (s is DoubleTapGestureState) {
      localListeners.notifyGesture(notifyId, s);
      return true;
    } else if (s is TripleTapGestureState) {
      localListeners.notifyGesture(notifyId, s);
      return true;
    } else if (s is PanGestureState) {
      final currentOffsetContains = box.containsOffset(s.globalOffset);
      if (!currentOffsetContains) return false;
      final beginOffsetContains = box.containsOffset(s.beginOffset);
      if (beginOffsetContains) {
        localListeners.notifyGesture(notifyId, s);
        return true;
      } else {
        final beginHigherThanCurrent = s.beginOffset.dy < s.globalOffset.dy;
        operator.onPanUpdate(EditingCursor(widgetIndex,
            beginHigherThanCurrent ? node.endPosition : node.beginPosition));
      }
    }
    return false;
  }

  void onArrowAccept(AcceptArrowData data) {
    final type = data.type;
    late CodeBlockPosition p;
    final cursor = data.cursor;
    if (cursor is EditingCursor) {
      if (cursor.position is! CodeBlockPosition) return;
      p = cursor.position as CodeBlockPosition;
    } else if (cursor is SelectingNodeCursor) {
      if (cursor.end is! CodeBlockPosition) return;
      p = cursor.end as CodeBlockPosition;
    } else {
      return;
    }
    final index = p.index;
    logger.i('$tag, onArrowAccept $data');
    CodeBlockPosition? newPosition;
    switch (type) {
      case ArrowType.current:
        final box = renderBox;
        if (box == null) return;
        final extra = data.extras;
        if (extra is Offset) {
          final h = lineHeight;
          final globalOffset = box.localToGlobal(Offset.zero);
          final globalY = globalOffset.dy;
          Offset? tapOffset;
          if (p == node.endPosition) {
            tapOffset =
                Offset(extra.dx, globalY + box.size.height - padding.bottom);
          } else if (p == node.beginPosition) {
            tapOffset = Offset(extra.dx, globalY + h + padding.top);
          }
          if (tapOffset == null) return;
          localListeners.notifyGesture(
              '$nodeId$index', TapGestureState(tapOffset));
        } else {
          newPosition = p;
        }
        break;
      case ArrowType.left:
        newPosition = node.lastPosition(p);
        break;
      case ArrowType.right:
        newPosition = node.nextPosition(p);
        break;
      case ArrowType.up:
        final lastIndex = p.index - 1;
        if (lastIndex < 0) throw ArrowUpTopException(p, lastEditOffset);
        final lastCode = codes[lastIndex];
        final minOffset = min(lastCode.length, p.offset);
        newPosition = CodeBlockPosition(lastIndex, minOffset);
        break;
      case ArrowType.down:
        final nextIndex = p.index + 1;
        if (nextIndex > codes.length - 1) {
          throw ArrowDownBottomException(p, lastEditOffset);
        }
        final nextCode = codes[nextIndex];
        final minOffset = min(nextCode.length, p.offset);
        newPosition = CodeBlockPosition(nextIndex, minOffset);
        break;
      case ArrowType.lastWord:
        try {
          localListeners.onArrowAccept(data.newId('$nodeId$index'));
        } on ArrowLeftBeginException {
          if (index == 0) rethrow;
          newPosition = CodeBlockPosition(index - 1, codes[index - 1].length);
        }
        break;
      case ArrowType.nextWord:
        try {
          localListeners.onArrowAccept(data.newId('$nodeId$index'));
        } on ArrowRightEndException {
          if (index == codes.length - 1) rethrow;
          newPosition = CodeBlockPosition(index + 1, 0);
        }
        break;
      default:
        break;
    }
    if (newPosition != null) {
      operator.onCursor(EditingCursor(widgetIndex, newPosition));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool allSelected = isAllSelected();
    final editorContext = ShareEditorContextWidget.of(context)?.context;
    return Padding(
      key: key,
      padding: margin,
      child: Stack(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.text,
            onEnter: (e) => toHover(),
            onHover: (e) => toHover(),
            onExit: (e) => hoveredNotifier.value = false,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.hoverColor),
              foregroundDecoration: allSelected
                  ? BoxDecoration(
                      color: Colors.blue.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Row(
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(codes.length, (index) {
                        return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: lineHeight,
                            child: Center(
                                child: Text(
                              '${index + 1}.',
                              style: theme.textTheme.bodyMedium,
                            )));
                      })),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(codes.length, (index) {
                          final code = codes[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            height: lineHeight,
                            child: CodeBlockLine(
                              code: code,
                              dark: theme.brightness == Brightness.dark,
                              language: node.language,
                              editingOffset: getEditingOffset(index),
                              selectingOffset: getSelectingRange(index),
                              style: theme.textTheme.bodyMedium,
                              controller: CodeNodeController(
                                  onEditingOffsetChanged: (o) {
                                    lastEditOffset = o.offset;
                                    operator.onEditingOffset(o);
                                  },
                                  onPanUpdatePosition: (o) =>
                                      operator.onPanUpdate(EditingCursor(
                                          widgetIndex,
                                          CodeBlockPosition(index, o))),
                                  listeners: localListeners,
                                  onEditingPosition: (o) => operator.onCursor(
                                      EditingCursor(widgetIndex,
                                          CodeBlockPosition(index, o))),
                                  onLineSelected: (range) => operator.onCursor(
                                      SelectingNodeCursor(
                                          widgetIndex,
                                          CodeBlockPosition(index, range.start),
                                          CodeBlockPosition(
                                              index, range.end)))),
                              nodeId: '$nodeId$index',
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder(
              valueListenable: hoveredNotifier,
              builder: (context, v, c) {
                if (!v) return Container();
                return Positioned(
                  child: OverlayPortal(
                    controller: languageController,
                    overlayChildBuilder: (ctx) {
                      return LanguageSelectMenu(
                        languages: constLanguages,
                        onSelect: (s) {
                          if (s == node.language) return;
                          operator.onNode(node.newLanguage(s), widgetIndex);
                        },
                        onHide: () {
                          languageController.hide();
                          editorContext?.controller
                              .updateStatus(ControllerStatus.idle);
                        },
                      );
                    },
                    child: InkWell(
                      onTap: () {
                        editorContext?.controller
                            .updateStatus(ControllerStatus.typing);
                        languageController.show();
                      },
                      onHover: (e) => toHover(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(node.language),
                          Icon(Icons.arrow_drop_down_rounded)
                        ],
                      ),
                    ),
                  ),
                  left: 8,
                  top: 0,
                );
              })
        ],
      ),
    );
  }

  void toHover() {
    if (!hoveredNotifier.value) {
      hoveredNotifier.value = true;
    }
  }

  int? getEditingOffset(int index) {
    final cursor = nodeCursor;
    if (cursor is EditingCursor) {
      final p = cursor.position;
      if (p is! CodeBlockPosition) return null;
      if (p.index != index) return null;
      return p.offset;
    }
    return null;
  }

  TextRange? getSelectingRange(int index) {
    if (isAllSelected()) return null;
    final cursor = nodeCursor;
    if (cursor is! SelectingNodeCursor) return null;
    final left = cursor.left;
    final right = cursor.right;
    if (left is! CodeBlockPosition || right is! CodeBlockPosition) return null;
    if (index > left.index && index < right.index) {
      return TextRange(start: 0, end: codes[index].length);
    }
    if (index < left.index) return null;
    if (index > right.index) return null;
    if (left.index == right.index) {
      if (index != left.index) return null;
      return TextRange(start: left.offset, end: right.offset);
    } else {
      if (index == left.index) {
        return TextRange(start: left.offset, end: codes[index].length);
      } else if (index == right.index) {
        return TextRange(start: 0, end: right.offset);
      }
    }
    return null;
  }

  bool isAllSelected() {
    final cursor = nodeCursor;
    if (cursor is! SelectingNodeCursor) return false;
    final left = cursor.left;
    final right = cursor.right;
    if (left == node.beginPosition || right == node.endPosition) {
      return true;
    }
    return false;
  }
}

final constLanguages = UnmodifiableListView(builtinLanguages.keys.toList());
