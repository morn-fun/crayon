import 'dart:math';

import 'package:flutter/material.dart';

import '../../command/replace.dart';
import '../../core/context.dart';
import '../../core/controller.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic_cursor.dart';
import '../../cursor/rich_text_cursor.dart';
import '../../node/basic_node.dart';
import '../../node/rich_text_node/head_node.dart';
import '../../node/rich_text_node/ordered_node.dart';
import '../../node/rich_text_node/rich_text_node.dart';
import '../../node/rich_text_node/unordered_node.dart';

///TODO:auto scroll with arrow
class OptionalMenu extends StatefulWidget {
  final Offset offset;
  final EditorContext editorContext;

  const OptionalMenu({
    super.key,
    required this.offset,
    required this.editorContext,
  });

  @override
  State<OptionalMenu> createState() => _OptionalMenuState();
}

class _OptionalMenuState extends State<OptionalMenu> {
  Offset get offset => widget.offset;

  EditorContext get editorContext => widget.editorContext;

  RichEditorController get controller => editorContext.controller;

  ListenerCollection get listeners => controller.listeners;

  final ValueNotifier<int> currentIndex = ValueNotifier(1);
  bool isCheckingText = false;

  final list = List.of(defaultMenus);

  late String nodeId;

  @override
  void initState() {
    final cursor = controller.cursor as EditingCursor;
    nodeId = controller.getNode(cursor.index).id;
    listeners.addCursorChangedListener(_onCursorChanged);
    listeners.addNodeChangedListener(nodeId, _onNodeChanged);
    listeners.addOptionalMenuListener(_onOptionalMenuSelected);
    super.initState();
  }

  @override
  void dispose() {
    listeners.removeCursorChangedListener(_onCursorChanged);
    listeners.removeNodeChangedListener(nodeId, _onNodeChanged);
    listeners.removeOptionalMenuListener(_onOptionalMenuSelected);
    currentIndex.dispose();
    super.dispose();
  }

  void _onCursorChanged(BasicCursor cursor) {
    if (cursor is! EditingCursor) {
      hideMenu();
      return;
    }
    final node = controller.getNode(cursor.index);
    if (node.id != nodeId) return;
    checkText(node, cursor);
  }

  void hideMenu() => editorContext.hideMenu();

  void _onNodeChanged(EditorNode node) {
    final cursor = controller.cursor;
    if (cursor is! EditingCursor) return;
    checkText(node, cursor);
  }

  void checkText(EditorNode node, EditingCursor<NodePosition> cursor) {
    if (isCheckingText) return;
    isCheckingText = true;
    final text = node.frontPartNode(cursor.position).text;
    if (!text.contains('/')) hideMenu();
    isCheckingText = false;
  }

  void _onOptionalMenuSelected(OptionalSelectedType type) {
    int v = currentIndex.value;
    switch (type) {
      case OptionalSelectedType.last:
        v--;
        while (v >= 0) {
          final current = list[v];
          if (current.interactive) break;
          v--;
        }
        currentIndex.value = max(v, 1);
        break;
      case OptionalSelectedType.next:
        v++;
        while (v < list.length) {
          final current = list[v];
          if (current.interactive) break;
          v++;
        }
        currentIndex.value = min(v, list.length - 1);
        break;
      case OptionalSelectedType.current:
        final current = list[v];
        if (!current.interactive) return;
        _onItemSelected(current);
        break;
    }
  }

  void _onItemSelected(MenuItemInfo current) {
    hideMenu();
    final cursor = controller.cursor;
    if (cursor is! EditingCursor) return;
    final node = controller.getNode(cursor.index);
    if (node.id != nodeId) return;
    if (node is! RichTextNode) return;
    if (current.generator == null) return;

    ///TODO:avoid hardcode here
    final nodes = current.generator!
        .call(node.rearPartNode(cursor.position as RichTextNodePosition));
    editorContext.execute(ReplaceNode(Replace(
      cursor.index,
      cursor.index + 1,
      nodes,
      EditingCursor(cursor.index, nodes.last.beginPosition),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final info = _correctCoordinate(Size(size.width - 10, size.height - 10),
        widget.offset.translate(0, 18));
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => hideMenu(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned(
                child: Card(
                  elevation: 10,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Container(
                    height: info.size.height,
                    width: info.size.width,
                    child: ValueListenableBuilder(
                        valueListenable: currentIndex,
                        builder: (context, v, c) {
                          return ListView.builder(
                            padding: EdgeInsets.all(8),
                            itemCount: list.length,
                            itemBuilder: (ctx, index) {
                              final isCurrent = v == index;
                              final current = list[index];
                              return buildItem(
                                  index, isCurrent, theme, current);
                            },
                          );
                        }),
                  ),
                ),
                left: info.position.dx,
                top: info.position.dy),
          ],
        ),
      ),
    );
  }

  Widget buildItem(
      int index, bool isCurrent, ThemeData theme, MenuItemInfo current) {
    if (!current.interactive) {
      return Padding(
        padding: EdgeInsets.all(4),
        child: Text(
          current.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (e) {
        currentIndex.value = index;
      },
      child: GestureDetector(
        onTap: () => _onItemSelected(current),
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isCurrent ? theme.hoverColor : null,
          ),
          child: Row(
            children: [
              Icon(
                current.iconData,
                color: current.iconColor,
                size: 24,
              ),
              SizedBox(width: 16),
              Text(
                current.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CoordinateInfo _correctCoordinate(Size screenSize, Offset offset) {
    const widgetSize = Size(220, 600);
    const minHeight = 300;
    const minWidth = 200;
    const distanceY = 18;
    final resetDistanceToBottom = screenSize.height - offset.dy;
    final resetDistanceToRight = screenSize.width - offset.dx;
    final showInTop = resetDistanceToBottom < minHeight;
    final showInLeft = resetDistanceToRight < minWidth;
    double width = widgetSize.width;
    double height = widgetSize.height;
    double x = offset.dx;
    double y = offset.dy;
    if (showInTop) {
      height = min(y - distanceY, widgetSize.height);
      y = max(y - height - distanceY, 0);
    } else {
      height = min(resetDistanceToBottom, widgetSize.height);
    }
    if (showInLeft) {
      width = min(x, widgetSize.width);
      x = max(x - width, 0);
    } else {
      width = min(resetDistanceToRight, widgetSize.width);
    }

    return _CoordinateInfo(Size(width, height), Offset(x, y));
  }
}

class _CoordinateInfo {
  final Offset position;
  final Size size;

  _CoordinateInfo(this.size, this.position);
}

enum OptionalSelectedType { last, next, current }

final defaultMenus = [
  MenuItemInfo.readable('基础'),
  MenuItemInfo.normal('文本', Icons.text_fields_rounded, _textColor, (n) => [n]),
  MenuItemInfo.normal('一级标题', Icons.title_rounded, _textColor,
      (n) => [H1Node.from(n.spans, id: n.id, depth: n.depth)]),
  MenuItemInfo.normal('二级标题', Icons.title_rounded, _textColor,
      (n) => [H2Node.from(n.spans, id: n.id, depth: n.depth)]),
  MenuItemInfo.normal('三级标题', Icons.title_rounded, _textColor,
      (n) => [H3Node.from(n.spans, id: n.id, depth: n.depth)]),
  MenuItemInfo.normal('有序列表', Icons.format_list_numbered_rounded, _textColor,
      (n) => [OrderedNode.from(n.spans, id: n.id, depth: n.depth)]),
  MenuItemInfo.normal('无序列表', Icons.list_rounded, _textColor,
      (n) => [UnorderedNode.from(n.spans, id: n.id, depth: n.depth)]),
  MenuItemInfo.normal('代码块', Icons.question_mark_rounded, Colors.red, null),
  MenuItemInfo.normal('引用', Icons.question_mark_rounded, Colors.red, null),
  MenuItemInfo.normal('分割线', Icons.question_mark_rounded, Colors.red, null),
  MenuItemInfo.normal('链接', Icons.question_mark_rounded, Colors.red, null),
];

const _textColor = Colors.brown;
// const _codeColor = Colors.cyan;
// const _linkColor = Colors.blue;
// const _quoteColor = Colors.yellow;

class MenuItemInfo {
  final String text;
  final IconData? iconData;
  final Color? iconColor;
  final bool interactive;
  final NodeGenerator? generator;

  MenuItemInfo.readable(this.text)
      : iconData = null,
        iconColor = null,
        interactive = false,
        generator = null;

  MenuItemInfo.normal(this.text, this.iconData, this.iconColor, this.generator)
      : interactive = true;
}

typedef NodeGenerator = List<EditorNode> Function(RichTextNode node);
