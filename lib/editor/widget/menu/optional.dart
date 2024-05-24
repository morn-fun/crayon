import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic.dart';
import '../../cursor/rich_text.dart';
import '../../node/basic.dart';
import '../../node/code_block/code_block.dart';
import '../../node/rich_text/head.dart';
import '../../node/rich_text/ordered.dart';
import '../../node/rich_text/quote.dart';
import '../../node/rich_text/rich_text.dart';
import '../../node/rich_text/task.dart';
import '../../node/rich_text/unordered.dart';
import '../../node/table/table.dart';

///TODO:auto scroll with arrow
class OptionalMenu extends StatefulWidget {
  final EditingOffset offset;
  final NodesOperator nodeContext;
  final EntryManager manager;

  const OptionalMenu(
    this.offset,
    this.nodeContext,
    this.manager, {
    super.key,
  });

  @override
  State<OptionalMenu> createState() => _OptionalMenuState();
}

class _OptionalMenuState extends State<OptionalMenu> {
  EditingOffset get offset => widget.offset;

  NodesOperator get nodeContext => widget.nodeContext;

  ListenerCollection get listeners => nodeContext.listeners;

  EntryManager get manager => widget.manager;

  final ValueNotifier<int> currentIndex = ValueNotifier(1);

  bool isCheckingText = false;

  final list = List.of(defaultMenus);

  late String nodeId;
  late EditingCursor cursor;
  late RichTextNode node;

  @override
  void initState() {
    cursor = nodeContext.cursor as EditingCursor;
    node = nodeContext.getNode(cursor.index) as RichTextNode;
    nodeId = node.id;
    if(nodeContext is TableCellNodeContext) list.removeWhere((e) => e.text == '表格');
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
    if(cursor.position is! RichTextNodePosition){
      hideMenu();
      return;
    }
    this.cursor = cursor;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      checkText(node, cursor);
    });
  }

  void hideMenu() {
    if (mounted) manager.removeEntry();
  }

  void _onNodeChanged(EditorNode node) {
    if(node.id != nodeId) hideMenu();
    if(node is! RichTextNode) {
      hideMenu();
      return;
    }
    this.node = node;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final c = cursor;
      checkText(node, c);
    });
  }

  void checkText(EditorNode node, EditingCursor cursor) {
    if (isCheckingText) return;
    isCheckingText = true;
    final text = node.frontPartNode(cursor.position).text;
    if (!text.contains('/')) {
      hideMenu();
      return;
    }
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
    final c = nodeContext.cursor;
    if (c is! EditingCursor) return;
    final node = nodeContext.getNode(c.index);
    if (node.id != nodeId) return;
    if (node is! RichTextNode) return;
    if (current.generator == null) return;
    final newNode = current.generator!
        .call(node.rearPartNode(c.position as RichTextNodePosition));
    nodeContext.update(Update(
        c.index, newNode, EditingCursor(c.index, newNode.beginPosition)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final off = widget.offset.offset;
    final info = _correctCoordinate(Size(size.width - 10, size.height - 10),
        off.translate(0, offset.height));
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
    double distanceY = this.offset.height;
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
  MenuItemInfo.normal('文本', Icons.text_fields_rounded, _textColor, (n) => n),
  MenuItemInfo.normal('一级标题', Icons.title_rounded, _textColor,
      (n) => H1Node.from(n.spans, id: n.id, depth: n.depth)),
  MenuItemInfo.normal('二级标题', Icons.title_rounded, _textColor,
      (n) => H2Node.from(n.spans, id: n.id, depth: n.depth)),
  MenuItemInfo.normal('三级标题', Icons.title_rounded, _textColor,
      (n) => H3Node.from(n.spans, id: n.id, depth: n.depth)),
  MenuItemInfo.normal('有序列表', Icons.format_list_numbered_rounded, _textColor,
      (n) => OrderedNode.from(n.spans, id: n.id, depth: n.depth)),
  MenuItemInfo.normal('无序列表', Icons.list_rounded, _textColor,
      (n) => UnorderedNode.from(n.spans, id: n.id, depth: n.depth)),
  MenuItemInfo.normal('代码块', Icons.code, _codeColor,
      (n) => CodeBlockNode.from([], id: n.id, depth: n.depth)),
  MenuItemInfo.normal('引用', Icons.format_quote_rounded, _quoteColor,
      (n) => QuoteNode.from([], id: n.id, depth: n.depth)),
  MenuItemInfo.normal('分割线', Icons.question_mark_rounded, Colors.red, null),
  MenuItemInfo.normal('链接', Icons.question_mark_rounded, _linkColor, null),
  MenuItemInfo.readable('常用'),
  MenuItemInfo.normal('任务列表', Icons.task_rounded, _textColor,
      (n) => TodoNode.from([], id: n.id, depth: n.depth)),
  MenuItemInfo.normal('表格', Icons.table_chart_rounded, _textColor,
      (n) => TableNode.from([], [], id: n.id, depth: n.depth)),
];

const _textColor = Colors.brown;
const _codeColor = Colors.cyan;
const _linkColor = Colors.blue;
const _quoteColor = Colors.yellow;

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

typedef NodeGenerator = EditorNode Function(RichTextNode node);
