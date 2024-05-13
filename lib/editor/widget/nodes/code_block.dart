import 'dart:collection';
import 'dart:math';

import '../../../../editor/extension/render_box.dart';
import 'package:flutter/material.dart';
import 'package:highlight/languages/all.dart';

import '../../core/context.dart';
import '../../../editor/cursor/basic.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../../cursor/code_block.dart';
import '../../exception/editor_node.dart';
import '../../node/code_block/code_block.dart';
import '../../cursor/node_position.dart';
import '../../shortcuts/arrows/arrows.dart';
import '../../../editor/core/editor_controller.dart';
import '../../../editor/extension/node_context.dart';
import '../menu/code_selector.dart';
import 'code_block_line.dart';

class CodeBlock extends StatefulWidget {
  const CodeBlock(
    this.context,
    this.node,
    this.param, {
    super.key,
    this.maxLineHeight = 20,
  });

  final NodeContext context;
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

  NodeContext get nodeContext => widget.context;

  ListenerCollection get listeners => nodeContext.listeners;

  ListenerCollection localListeners = ListenerCollection();

  List<String> get codes => node.codes;

  Offset lastEditOffset = Offset.zero;

  SingleNodePosition? get nodePosition => widget.param.position;

  int get widgetIndex => widget.param.index;

  final padding = EdgeInsets.all(24);

  final hoveredNotifier = ValueNotifier(false);

  final languageController = OverlayPortalController();

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  @override
  void initState() {
    super.initState();
    listeners.addArrowDelegate(node.id, onArrowAccept);
    listeners.addGestureListener(node.id, onGesture);
  }

  @override
  void dispose() {
    listeners.removeArrowDelegate(node.id, onArrowAccept);
    listeners.removeGestureListener(node.id, onGesture);
    localListeners.dispose();
    hoveredNotifier.dispose();
    super.dispose();
  }

  void onGesture(GestureState s) {
    final box = renderBox;
    if (box == null) return;
    if (s is TapGestureState) {
      bool contains = box.containsOffset(s.globalOffset);
      if (contains) localListeners.notifyGestures(s);
    } else if (s is PanGestureState) {
      final currentOffsetContains = box.containsOffset(s.globalOffset);
      if (!currentOffsetContains) return;
      final beginOffsetContains = box.containsOffset(s.beginOffset);
      if (beginOffsetContains) {
        localListeners.notifyGestures(s);
      } else {
        final beginHigherThanCurrent = s.beginOffset.dy < s.globalOffset.dy;
        nodeContext.onPanUpdate(EditingCursor(widgetIndex,
            beginHigherThanCurrent ? node.endPosition : node.beginPosition));
      }
    }
  }

  void onArrowAccept(AcceptArrowData data) {
    final type = data.type;
    final p = data.position;
    logger.i('$tag, onArrowAccept $data');
    if (p is! CodeBlockPosition) return;
    CodeBlockPosition? newPosition;
    switch (type) {
      case ArrowType.current:
        final box = renderBox;
        if (box == null) return;
        final extra = data.extras;
        if (extra is Offset) {
          final h = widget.maxLineHeight;
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
          localListeners.notifyGestures(TapGestureState(tapOffset));
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
      default:
        break;
    }
    if (newPosition != null) {
      nodeContext.onCursor(EditingCursor(widgetIndex, newPosition));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool allSelected = isAllSelected();
    return Stack(
      key: key,
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
                          height: widget.maxLineHeight,
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
                          height: widget.maxLineHeight,
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
                                nodeContext
                                    .onCursorOffset(CursorOffset(index, o));
                              },
                              onPanUpdatePosition: (o) =>
                                  nodeContext.onPanUpdate(EditingCursor(
                                      widgetIndex,
                                      CodeBlockPosition(index, o))),
                              listeners: localListeners,
                              onEditingPosition: (o) => nodeContext.onCursor(
                                  EditingCursor(widgetIndex,
                                      CodeBlockPosition(index, o))),
                            ),
                            nodeId: node.id,
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
                        nodeContext.onNode(node.newLanguage(s), widgetIndex);
                      },
                      onHide: () {
                        languageController.hide();
                        listeners.notifyStatus(ControllerStatus.idle);
                      },
                    );
                  },
                  child: InkWell(
                    onTap: () {
                      listeners.notifyStatus(ControllerStatus.typing);
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
    );
  }

  void toHover() {
    if (!hoveredNotifier.value) {
      hoveredNotifier.value = true;
    }
  }

  int? getEditingOffset(int index) {
    final position = nodePosition;
    if (position is EditingPosition) {
      final p = position.position;
      if (p is! CodeBlockPosition) return null;
      if (p.index != index) return null;
      return p.offset;
    }
    return null;
  }

  TextRange? getSelectingRange(int index) {
    if (isAllSelected()) return null;
    final position = nodePosition;
    if (position is! SelectingPosition) return null;
    final left = position.left;
    final right = position.right;
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
    final position = nodePosition;
    if (position is! SelectingPosition) return false;
    final left = position.left;
    final right = position.right;
    if (left == node.beginPosition || right == node.endPosition) {
      return true;
    }
    return false;
  }
}

final constLanguages = UnmodifiableListView(builtinLanguages.keys.toList());
