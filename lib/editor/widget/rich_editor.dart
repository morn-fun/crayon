import 'package:flutter/material.dart';
import 'package:pre_editor/editor/exception/command_exception.dart';

import '../core/context.dart';
import '../core/controller.dart';
import '../core/input_manager.dart';
import '../core/logger.dart';
import '../node/basic_node.dart';
import '../shortcuts/shortcuts.dart';

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

  final focusNode = FocusNode();

  final _tag = 'rich_editor';

  @override
  void initState() {
    super.initState();
    controller = RichEditorController.fromNodes(widget.nodes);
    manager = ShortcutManager(shortcuts: shortcuts, modal: true);
    inputManager = InputManager(controller, manager, (c) {
      try {
        controller.execute(c);
      } on PerformCommandException catch (e) {
        logger.e('$e');
      }
    });
    inputManager.startInput();
    editorContext = EditorContext(controller, inputManager, focusNode);
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
    focusNode.removeListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    final hasFocus = focusNode.hasFocus;
    logger.i('$_tag, hasFocus:$hasFocus');
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
          child: ListView.builder(
              itemBuilder: (ctx, index) {
                var current = nodes[index];
                return Container(
                    key: ValueKey(current.id),
                    child: current.build(editorContext, index));
              },
              itemCount: nodes.length),
        ),
      ),
    );
  }
}
