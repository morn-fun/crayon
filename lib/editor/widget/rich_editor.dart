import 'package:flutter/material.dart';
import 'package:pre_editor/editor/exception/command_exception.dart';

import '../core/command_invoker.dart';
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
  late CommandInvoker commandInvoker;
  late EditorContext editorContext;

  final focusNode = FocusNode();

  final _tag = 'rich_editor';

  @override
  void initState() {
    super.initState();
    controller = RichEditorController.fromNodes(widget.nodes);
    commandInvoker = CommandInvoker();
    inputManager = InputManager(controller, (c) {
      try {
        commandInvoker.execute(c.command, controller, record: c.record);
      } on PerformCommandException catch (e) {
        logger.e('$e');
      }
    });
    inputManager.startInput();
    editorContext = EditorContext(controller, inputManager, commandInvoker, focusNode);
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
    commandInvoker.dispose();
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
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: getActions(editorContext),
        child: Focus(
          focusNode: focusNode,
          child: ListView.builder(
              itemBuilder: (ctx, index) {
                var current = nodes[index];
                return current.build(editorContext, index);
              },
              itemCount: nodes.length),
        ),
      ),
    );
  }
}
