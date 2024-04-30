import 'dart:collection';
import 'dart:math';

import 'package:crayon/editor/core/editor_controller.dart';
import 'package:flutter/material.dart';
import 'package:highlight/languages/all.dart';

import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../../core/node_controller.dart';
import '../../cursor/code_block.dart';
import '../../exception/editor_node.dart';
import '../../node/code_block/code_block_node.dart';
import '../../cursor/node_position.dart';

import '../../shortcuts/arrows/arrows.dart';
import '../editor/shared_editor_context_widget.dart';
import '../menu/code_selector.dart';
import 'code_block_line.dart';

class CodeBlock extends StatefulWidget {
  const CodeBlock({
    super.key,
    required this.controller,
    required this.node,
    this.position,
    this.maxLineHeight = 20,
  });

  final NodeController controller;
  final CodeBlockNode node;
  final SingleNodePosition? position;
  final double maxLineHeight;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  final tag = 'CodeBlock';

  final key = GlobalKey();

  CodeBlockNode get node => widget.node;

  NodeController get controller => widget.controller;

  ListenerCollection get listeners => controller.listeners;

  List<String> get codes => node.codes;

  Offset lastEditOffset = Offset.zero;

  SingleNodePosition? get nodePosition => widget.position;

  final padding = EdgeInsets.all(24);

  final hoveredNotifier = ValueNotifier(false);

  final languageController = OverlayPortalController();

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    listeners.addArrowDelegate(node.id, onArrowAccept);
  }

  @override
  void dispose() {
    listeners.removeArrowDelegate(node.id, onArrowAccept);
    hoveredNotifier.dispose();
    super.dispose();
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
          listeners.notifyGesture(GestureState(GestureType.tap, tapOffset));
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
      controller.notifyEditingPosition(newPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool allSelected = isAllSelected();
    final editorContext = ShareEditorContextWidget.of(context)?.context;
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
                                lastEditOffset = o;
                                controller.notifyEditingOffset(o.dy);
                              },
                              onInputConnectionAttribute:
                                  controller.onInputConnectionAttribute,
                              onPanUpdatePosition: (o) =>
                                  controller.notifyPositionWhilePanGesture(
                                      CodeBlockPosition(index, o)),
                              listeners: controller.listeners,
                              onEditingPosition: (o) =>
                                  controller.notifyEditingPosition(
                                      CodeBlockPosition(index, o)),
                            ),
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
                        controller.updateNode(node.newLanguage(s));
                      },
                      onHide: () {
                        languageController.hide();
                        editorContext?.updateStatus(ControllerStatus.idle);
                        editorContext?.requestFocus();
                      },
                    );
                  },
                  child: InkWell(
                    onTap: () {
                      editorContext?.updateStatus(ControllerStatus.typing);
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
    if (left == node.beginPosition && right == node.endPosition) {
      return true;
    }
    return false;
  }
}

final constLanguages = UnmodifiableListView(builtinLanguages.keys.toList());
