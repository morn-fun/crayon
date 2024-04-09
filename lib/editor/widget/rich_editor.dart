import 'package:flutter/material.dart';
import '../core/command_invoker.dart';
import '../core/context.dart';
import '../core/controller.dart';
import '../core/input_manager.dart';
import '../core/logger.dart';
import '../node/basic_node.dart';
import '../shortcuts/shortcuts.dart';
import '../../editor/exception/command_exception.dart';

class RichEditor extends StatefulWidget {
  final List<EditorNode> nodes;

  const RichEditor({super.key, this.nodes = const []});

  @override
  State<RichEditor> createState() => _RichEditorPageState();
}

class _RichEditorPageState extends State<RichEditor> {
  late RichEditorController controller;
  late InputManager inputManager;
  late EditorContext editorContext;
  late ShortcutManager manager;
  final CommandInvoker invoker = CommandInvoker();
  Offset _panOffset = Offset.zero;
  bool _hasTapDown = false;

  final focusNode = FocusNode();

  final tag = 'rich_editor';

  @override
  void initState() {
    super.initState();
    controller = RichEditorController.fromNodes(widget.nodes);
    manager = ShortcutManager(shortcuts: editorShortcuts, modal: true);
    inputManager = InputManager(controller, manager, (c) {
      try {
        invoker.execute(c, controller);
      } on PerformCommandException catch (e) {
        logger.e('$e');
      }
    }, () => focusNode.requestFocus());
    inputManager.startInput();
    editorContext = EditorContext(controller, inputManager, focusNode, invoker);
    focusNode.requestFocus();
    focusNode.addListener(_onFocusChanged);
    controller.addNodesChangedCallback(refresh);
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    inputManager.dispose();
    controller.dispose();
    manager.dispose();
    invoker.dispose();
    focusNode.removeListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    final hasFocus = focusNode.hasFocus;
    logger.i('$tag, hasFocus:$hasFocus');
    if (!hasFocus) {
      inputManager.stopInput();
    } else {
      inputManager.startInput();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodes = controller.nodes;
    return Shortcuts.manager(
      manager: manager,
      child: Actions(
        actions: getActions(editorContext),
        child: Focus(
          focusNode: focusNode,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (detail) {
              controller.notifyTapDown(detail.globalPosition);
            },
            onPanStart: (d) {
              _panOffset = d.globalPosition;
            },
            onPanEnd: (d) {
              controller.notifyDragUpdateDetails(_panOffset);
            },
            onPanDown: (d) {
              _panOffset = d.globalPosition;
              _hasTapDown = true;
            },
            onPanUpdate: (d) {
              if (_hasTapDown) {
                controller.notifyTapDown(_panOffset);
                _hasTapDown = false;
              }
              _panOffset = _panOffset.translate(d.delta.dx, d.delta.dy);
              Throttle.execute(
                () => controller.notifyDragUpdateDetails(d.globalPosition),
                tag: tag,
                duration: const Duration(milliseconds: 50),
              );
            },
            onPanCancel: () {
              _panOffset = Offset.zero;
              _hasTapDown = false;
            },
            child: ListView.builder(
                padding: EdgeInsets.all(8),
                itemBuilder: (ctx, index) {
                  final current = nodes[index];
                  return Container(
                      key: ValueKey(current.id),
                      padding: EdgeInsets.only(left: current.depth * 12),
                      child: current.build(editorContext, index));
                },
                itemCount: nodes.length),
          ),
        ),
      ),
    );
  }
}
