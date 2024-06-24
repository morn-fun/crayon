import 'package:flutter/material.dart';
import '../../../editor/extension/collection.dart';
import '../../../editor/cursor/rich_text.dart';
import '../../../editor/extension/cursor.dart';

import '../../core/context.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../../cursor/basic.dart';
import '../../node/basic.dart';
import '../../node/rich_text/rich_text_span.dart';
import '../../shortcuts/styles.dart';

class TextMenu extends StatefulWidget {
  final NodesOperator operator;
  final MenuInfo info;
  final EntryManager manager;

  const TextMenu(this.operator, this.info, this.manager, {super.key});

  @override
  State<TextMenu> createState() => _TextMenuState();
}

class _TextMenuState extends State<TextMenu> {
  ListenerCollection get listeners => operator.listeners;

  MenuInfo get info => widget.info;

  EntryManager get manager => widget.manager;

  Set<String> tagSets = {};

  late NodesOperator operator = widget.operator;

  late BasicCursor cursor = operator.cursor;

  late List<EditorNode> nodes = List.of(operator.nodes);

  EditorNode? node;

  @override
  void initState() {
    listeners.addCursorChangedListener(onCursorChanged);
    listeners.addNodesChangedListener(onNodesChanged);
    final c = cursor;
    tagSets = c.tagIntersection(nodes);
    if (c is SelectingNodeCursor) {
      node = operator.getNode(c.index);
      listeners.addNodeChangedListener(node!.id, onNodeChanged);
    }
    super.initState();
  }

  @override
  void dispose() {
    nodes.clear();
    listeners.removeCursorChangedListener(onCursorChanged);
    listeners.removeNodesChangedListener(onNodesChanged);
    if (node != null) {
      listeners.removeNodeChangedListener(node!.id, onNodeChanged);
    }
    super.dispose();
  }

  void onNodeChanged(EditorNode node) {
    if (this.node?.id != node.id) return;
    this.node = node;
    WidgetsBinding.instance.addPostFrameCallback((t) {
      if (!mounted) return;
      final c = cursor;
      if (c is! SelectingNodeCursor) return;
      try {
        nodes[c.index] = node;
        final newTags = cursor.tagIntersection(nodes);
        if (!newTags.equalsTo(tagSets)) refresh();
        tagSets = newTags;
      } catch (e) {
        logger.e('onNodeChanged error:$e');
      }
    });
  }

  void onCursorChanged(BasicCursor cursor) {
    this.cursor = cursor;
    if (cursor is EditingCursor) {
      hideMenu();
      return;
    }
    operator = operator.newOperator(nodes, cursor);
    WidgetsBinding.instance.addPostFrameCallback((t) {
      if (!mounted) return;
      try {
        final newTags = cursor.tagIntersection(nodes);
        if (!newTags.equalsTo(tagSets)) refresh();
        tagSets = newTags;
      } catch (e) {
        logger.e('onCursorChanged error:$e');
      }
    });
  }

  void onNodesChanged(List<EditorNode> nodes) {
    this.nodes = List.of(nodes);
    operator = operator.newOperator(nodes, cursor);
    WidgetsBinding.instance.addPostFrameCallback((t) {
      if (!mounted) return;
      try {
        final newTags = cursor.tagIntersection(nodes);
        if (!newTags.equalsTo(tagSets)) refresh();
        tagSets = newTags;
      } catch (e) {
        logger.e('onNodesChanged error:$e');
      }
    });
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void hideMenu() => manager.removeEntry();

  @override
  Widget build(BuildContext context) {
    double dy = info.offset.dy;
    double dx = info.offset.dx;
    final c = cursor;
    return Stack(
      children: [
        Positioned(
          top: dy,
          left: dx,
          child: Card(
            elevation: 2,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon(Icons.text_fields, size: 24),
                  // SizedBox(
                  //   width: 20,
                  //   height: 24,
                  //   child: Center(
                  //       child:
                  //           Icon(Icons.keyboard_arrow_down_rounded, size: 14)),
                  // ),
                  // verticalDivider(),
                  TextMenuItem(
                    iconData: Icons.format_bold,
                    onTap: () =>
                        onStyleEvent(operator, RichTextTag.bold, cursor),
                    contains: tagSets.contains(RichTextTag.bold.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_strikethrough_rounded,
                    onTap: () =>
                        onStyleEvent(operator, RichTextTag.lineThrough, cursor),
                    contains: tagSets.contains(RichTextTag.lineThrough.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_italic_rounded,
                    onTap: () =>
                        onStyleEvent(operator, RichTextTag.italic, cursor),
                    contains: tagSets.contains(RichTextTag.italic.name),
                  ),
                  TextMenuItem(
                    iconData: Icons.format_underline_rounded,
                    onTap: () =>
                        onStyleEvent(operator, RichTextTag.underline, cursor),
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
                          onStyleEvent(operator, RichTextTag.link, cursor);
                        } else {
                          final alias =
                              node?.getFromPosition(c.left, c.right).text ?? '';
                          manager.showLinkMenu(
                              Overlay.of(context),
                              LinkMenuInfo(
                                  c.as<RichTextNodePosition>(),
                                  info.globalOffset,
                                  info.nodeId,
                                  UrlInfo('', alias)),
                              operator);
                        }
                      },
                      contains: tagSets.contains(RichTextTag.link.name),
                    ),
                  TextMenuItem(
                    iconData: Icons.code,
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    onTap: () =>
                        onStyleEvent(operator, RichTextTag.code, cursor),
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
  final EdgeInsetsGeometry padding;

  const TextMenuItem({
    super.key,
    required this.iconData,
    required this.onTap,
    this.contains = false,
    this.padding = const EdgeInsets.only(left: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
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
