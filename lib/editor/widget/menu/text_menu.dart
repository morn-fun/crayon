import 'package:crayon/editor/extension/collection_extension.dart';
import 'package:flutter/material.dart';
import '../../../editor/extension/rich_editor_controller_extension.dart';

import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic_cursor.dart';
import '../../node/rich_text_node/rich_text_span.dart';
import '../../shortcuts/styles.dart';

class TextMenu extends StatefulWidget {
  final EditorContext editorContext;
  final MenuInfo info;
  final LayerLink link;

  const TextMenu(this.editorContext, this.info, this.link, {super.key});

  @override
  State<TextMenu> createState() => _TextMenuState();
}

class _TextMenuState extends State<TextMenu> {
  EditorContext get editorContext => widget.editorContext;

  RichEditorController get controller => editorContext.controller;

  ListenerCollection get listeners => controller.listeners;

  MenuInfo get info => widget.info;

  BasicCursor get cursor => editorContext.cursor;

  Set<String> tagSets = {};

  @override
  void initState() {
    listeners.addCursorChangedListener(onCursorChanged);
    listeners.addNodesChangedListener(onNodesChanged);
    tagSets = controller.tagIntersection();
    super.initState();
  }

  @override
  void dispose() {
    listeners.removeCursorChangedListener(onCursorChanged);
    listeners.removeNodesChangedListener(onNodesChanged);
    super.dispose();
  }

  void onCursorChanged(BasicCursor cursor) {
    if (cursor is EditingCursor) {
      hideMenu();
      return;
    }
    final newTags = controller.tagIntersection();
    if (!newTags.equalsTo(tagSets)) refresh();
    tagSets = newTags;
  }

  void onNodesChanged() {
    final newTags = controller.tagIntersection();
    if (!newTags.equalsTo(tagSets)) refresh();
    tagSets = newTags;
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void hideMenu() => editorContext.hideMenu();

  @override
  Widget build(BuildContext context) {
    double dy = info.lineHeight;
    double dx = info.offset.dx / 2;
    return Stack(
      children: [
        Positioned(
          top: dy,
          left: dx,
          child: Card(
            elevation: 10,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.text_fields, size: 24),
                  SizedBox(
                    width: 20,
                    height: 24,
                    child: Center(
                        child:
                            Icon(Icons.keyboard_arrow_down_rounded, size: 14)),
                  ),
                  verticalDivider(),
                  TextMenuItem(
                    iconData: Icons.format_bold,
                    onTap: () => onStyleEvent(editorContext, RichTextTag.bold),
                    contains: tagSets.contains(RichTextTag.bold.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_strikethrough_rounded,
                    onTap: () =>
                        onStyleEvent(editorContext, RichTextTag.lineThrough),
                    contains: tagSets.contains(RichTextTag.lineThrough.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_italic_rounded,
                    onTap: () =>
                        onStyleEvent(editorContext, RichTextTag.italic),
                    contains: tagSets.contains(RichTextTag.italic.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_underline_rounded,
                    onTap: () =>
                        onStyleEvent(editorContext, RichTextTag.underline),
                    contains: tagSets.contains(RichTextTag.underline.name),
                  ),
                  if (cursor is SelectingNodeCursor)
                    TextMenuItem(
                      iconData: Icons.link_rounded,
                      onTap: () {
                        hideMenu();
                        if (tagSets.contains(RichTextTag.link.name)) {
                          onStyleEvent(editorContext, RichTextTag.link,
                              attributes: {});
                        } else {
                          editorContext.updateEntryStatus(
                              EntryStatus.readyToShowingLinkMenu);
                          editorContext.showLinkMenu(
                              Overlay.of(context), info, widget.link);
                        }
                      },
                      contains: tagSets.contains(RichTextTag.link.name),
                    ),
                  TextMenuItem(
                    iconData: Icons.code,
                    onTap: () => onStyleEvent(editorContext, RichTextTag.code),
                    contains: tagSets.contains(RichTextTag.code.name),
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget verticalDivider() => Container(
        width: 1,
        height: 20,
        margin: EdgeInsets.only(left: 8),
        decoration: BoxDecoration(color: Colors.grey),
      );
}

class TextMenuItem extends StatelessWidget {
  final IconData iconData;
  final VoidCallback onTap;
  final bool contains;

  const TextMenuItem({
    super.key,
    required this.iconData,
    required this.onTap,
    this.contains = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child:
                Icon(iconData, size: 24, color: contains ? Colors.cyan : null),
          ),
          onTap: onTap),
    );
  }
}
