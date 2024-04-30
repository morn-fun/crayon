import 'package:flutter/material.dart';
import '../../core/command_invoker.dart';
import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/entry_manager.dart';
import '../../core/input_manager.dart';
import '../../core/logger.dart';
import '../../node/basic.dart';
import '../../core/shortcuts.dart';
import '../../exception/command.dart';
import 'auto_scroll_editor_list.dart';
import 'shared_editor_context_widget.dart';

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
  late EntryManager entryManager;
  late ShortcutManager shortcutManager;
  final CommandInvoker invoker = CommandInvoker();

  final focusNode = FocusNode();

  final tag = 'rich_editor';

  @override
  void initState() {
    super.initState();
    controller = RichEditorController.fromNodes(widget.nodes);
    final listeners = controller.listeners;
    entryManager = EntryManager((s) => listeners.notifyEntryStatus(s));
    shortcutManager = ShortcutManager(shortcuts: editorShortcuts, modal: true);
    inputManager = InputManager(
        controller: controller,
        onCommand: (c) {
          try {
            invoker.execute(c, editorContext);
          } on PerformCommandException catch (e) {
            logger.e('$e');
          }
        },
        focusCall: () => focusNode.requestFocus(),
        onEntryStatus: (s) => entryManager.updateStatus(s));
    inputManager.startInput();
    editorContext = EditorContext(
        controller, inputManager, focusNode, invoker, entryManager);
    focusNode.requestFocus();
    focusNode.addListener(_onFocusChanged);
    listeners.addNodesChangedListener(refresh);
    listeners.addStatusChangedListener((value) {
      entryManager.hideOptionalMenu();
      switch (value) {
        case ControllerStatus.typing:
          shortcutManager.shortcuts = {};
          break;
        case ControllerStatus.idle:
          shortcutManager.shortcuts = editorShortcuts;
          break;
      }
    });
    listeners.addEntryStatusChangedListener((value) {
      if (value == EntryStatus.showingOptionalMenu) {
        shortcutManager.shortcuts = selectingMenuShortcuts;
      } else {
        shortcutManager.shortcuts = editorShortcuts;
      }
    });
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.removeListener(_onFocusChanged);
    controller.dispose();
    inputManager.dispose();
    focusNode.dispose();
    invoker.dispose();
    entryManager.dispose();
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
    return Shortcuts.manager(
      manager: shortcutManager,
      child: Actions(
        actions: getActions(editorContext),
        child: Focus(
          focusNode: focusNode,
          child: ShareEditorContextWidget(
            child: AutoScrollEditorList(editorContext: editorContext),
            context: editorContext,
          ),
        ),
      ),
    );
  }
}
