import 'package:flutter/material.dart';
import '../../../editor/extension/rich_editor_controller_extension.dart';

import '../../core/context.dart';
import '../../core/controller.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic_cursor.dart';
import '../../node/rich_text_node/rich_text_span.dart';
import '../../shortcuts/styles.dart';

class TextMenu extends StatefulWidget {
  final EditorContext editorContext;
  final TextMenuInfo info;

  const TextMenu(this.editorContext, this.info, {super.key});

  @override
  State<TextMenu> createState() => _TextMenuState();
}

class _TextMenuState extends State<TextMenu> {
  EditorContext get editorContext => widget.editorContext;

  RichEditorController get controller => editorContext.controller;

  ListenerCollection get listeners => controller.listeners;

  TextMenuInfo get info => widget.info;

  Set<String> tagSets = {};

  @override
  void initState() {
    listeners.addCursorChangedListener(_onCursorChanged);
    tagSets = controller.tagIntersection();
    super.initState();
  }

  @override
  void dispose() {
    listeners.removeCursorChangedListener(_onCursorChanged);
    super.dispose();
  }

  void _onCursorChanged(BasicCursor cursor) {
    if (cursor is EditingCursor) {
      hideMenu();
      return;
    }
    tagSets = controller.tagIntersection();
    refresh();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void hideMenu() => editorContext.removeTextMenu();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    double dy = 18.0;
    double dx = info.offset.dx / 2;
    if (info.offset.dy + 18 >= h) {
      dy = -18.0;
    }
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
                    onTap: () {
                      BoldAction(editorContext).invoke(const BoldIntent());
                    },
                    contains: tagSets.contains(RichTextTag.bold.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_strikethrough_rounded,
                    onTap: () => LineThroughAction(editorContext)
                        .invoke(const LineThroughIntent()),
                    contains: tagSets.contains(RichTextTag.lineThrough.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_italic_rounded,
                    onTap: () => ItalicAction(editorContext)
                        .invoke(const ItalicIntent()),
                    contains: tagSets.contains(RichTextTag.italic.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_underline_rounded,
                    onTap: () => UnderlineAction(editorContext)
                        .invoke(const UnderlineIntent()),
                    contains: tagSets.contains(RichTextTag.underline.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.link_rounded,
                    onTap: () {},
                    contains: tagSets.contains(RichTextTag.link.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.code,
                    onTap: () {},
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
