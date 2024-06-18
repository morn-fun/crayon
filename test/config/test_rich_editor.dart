import 'package:crayon/editor/core/context.dart';
import 'package:crayon/editor/core/shortcuts.dart';
import 'package:crayon/editor/widget/editor/auto_scroll_editor_list.dart';
import 'package:crayon/editor/widget/editor/shared_node_context_widget.dart';
import 'package:flutter/material.dart';

class TestRichEditor extends StatefulWidget {
  const TestRichEditor(this.editorContext, {super.key});

  final EditorContext editorContext;

  @override
  State<TestRichEditor> createState() => _TestRichEditorState();
}

class _TestRichEditorState extends State<TestRichEditor> {
  late ShortcutManager shortcutManager;
  final focusNode = FocusNode();

  EditorContext get editorContext => widget.editorContext;

  @override
  void initState() {
    super.initState();
    final listeners = editorContext.controller.listeners;
    shortcutManager = ShortcutManager(shortcuts: editorShortcuts, modal: true);
    listeners.addNodesChangedListener((v) => refresh());
  }

  void refresh() {
    if (mounted) setState(() {});
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
