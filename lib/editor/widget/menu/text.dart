import 'package:flutter/material.dart';
import '../../../editor/extension/node_context.dart';
import '../../../editor/extension/collection.dart';
import '../../../editor/cursor/rich_text.dart';

import '../../core/context.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic.dart';
import '../../node/rich_text/rich_text_span.dart';
import '../../shortcuts/styles.dart';

class TextMenu extends StatefulWidget {
  final ValueGetter<NodeContext> contextGetter;
  final MenuInfo info;
  final EntryManager manager;

  const TextMenu(this.contextGetter, this.info, this.manager, {super.key});

  @override
  State<TextMenu> createState() => _TextMenuState();
}

class _TextMenuState extends State<TextMenu> {
  NodeContext get nodeContext => widget.contextGetter.call();

  ListenerCollection get listeners => nodeContext.listeners;

  MenuInfo get info => widget.info;

  EntryManager get manager => widget.manager;

  BasicCursor get cursor => nodeContext.cursor;

  Set<String> tagSets = {};

  @override
  void initState() {
    listeners.addCursorChangedListener(onCursorChanged);
    listeners.addNodesChangedListener(onNodesChanged);
    tagSets = nodeContext.tagIntersection(cursor);
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
    WidgetsBinding.instance.addPostFrameCallback((t) {
      if (!mounted) return;
      final newTags = nodeContext.tagIntersection(cursor);
      if (!newTags.equalsTo(tagSets)) refresh();
      tagSets = newTags;
    });
  }

  void onNodesChanged() {
    WidgetsBinding.instance.addPostFrameCallback((t) {
      if (!mounted) return;
      final newTags = nodeContext.tagIntersection(cursor);
      if (!newTags.equalsTo(tagSets)) refresh();
      tagSets = newTags;
    });
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void hideMenu() => manager.removeEntry();

  @override
  Widget build(BuildContext context) {
    double dy = info.lineHeight;
    double dx = info.offset.dx / 2;
    final c = cursor;
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
                    onTap: () => onStyleEvent(
                        nodeContext, RichTextTag.bold, nodeContext.cursor),
                    contains: tagSets.contains(RichTextTag.bold.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_strikethrough_rounded,
                    onTap: () => onStyleEvent(nodeContext,
                        RichTextTag.lineThrough, nodeContext.cursor),
                    contains: tagSets.contains(RichTextTag.lineThrough.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_italic_rounded,
                    onTap: () => onStyleEvent(
                        nodeContext, RichTextTag.italic, nodeContext.cursor),
                    contains: tagSets.contains(RichTextTag.italic.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_underline_rounded,
                    onTap: () => onStyleEvent(
                        nodeContext, RichTextTag.underline, nodeContext.cursor),
                    contains: tagSets.contains(RichTextTag.underline.name),
                  ),
                  if (c is SelectingNodeCursor &&
                      c.begin is RichTextNodePosition &&
                      c.end is RichTextNodePosition)
                    TextMenuItem(
                      iconData: Icons.link_rounded,
                      onTap: () {
                        hideMenu();
                        if (tagSets.contains(RichTextTag.link.name)) {
                          onStyleEvent(
                              nodeContext, RichTextTag.link, nodeContext.cursor,
                              attributes: {});
                        } else {
                          ///TODO:complete the logic here
                          // nodeContext.updateEntryStatus(
                          //     EntryStatus.readyToShowingLinkMenu);
                          // nodeContext.showLinkMenu(
                          //     Overlay.of(context), info, widget.link);
                        }
                      },
                      contains: tagSets.contains(RichTextTag.link.name),
                    ),
                  TextMenuItem(
                    iconData: Icons.code,
                    onTap: () => onStyleEvent(
                        nodeContext, RichTextTag.code, nodeContext.cursor),
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
