import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic.dart';
import '../../cursor/rich_text.dart';
import '../../exception/menu.dart';
import '../../node/basic.dart';
import '../../node/code_block/code_block.dart';
import '../../node/divider/divider.dart';
import '../../node/rich_text/head.dart';
import '../../node/rich_text/ordered.dart';
import '../../node/rich_text/quote.dart';
import '../../node/rich_text/rich_text.dart';
import '../../node/rich_text/task.dart';
import '../../node/rich_text/unordered.dart';
import '../../node/table/table.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

///TODO:auto scroll with arrow
class OptionalMenu extends StatefulWidget {
  final EditingOffset offset;
  final NodesOperator operator;
  final EntryManager manager;
  final List<MenuItemInfo> menuItems;

  const OptionalMenu(
    this.offset,
    this.operator,
    this.manager,
    this.menuItems, {
    super.key,
  });

  @override
  State<OptionalMenu> createState() => _OptionalMenuState();
}

class _OptionalMenuState extends State<OptionalMenu> {
  EditingOffset get offset => widget.offset;

  NodesOperator get operator => widget.operator;

  ListenerCollection get listeners => operator.listeners;

  EntryManager get manager => widget.manager;

  final ValueNotifier<int> currentIndex = ValueNotifier(1);

  bool isCheckingText = false;
  bool isCountingDown = false;

  late List<MenuItemInfo> list;

  late String nodeId;
  late EditingCursor cursor;
  late RichTextNode node;

  @override
  void initState() {
    cursor = operator.cursor as EditingCursor;
    node = operator.getNode(cursor.index) as RichTextNode;
    nodeId = node.id;
    list = List.of(widget.menuItems);
    listeners.addCursorChangedListener(onCursorChanged);
    listeners.addNodeChangedListener(nodeId, onNodeChanged);
    listeners.addOptionalMenuListener(onOptionalMenuSelected);
    super.initState();
  }

  @override
  void dispose() {
    listeners.removeCursorChangedListener(onCursorChanged);
    listeners.removeNodeChangedListener(nodeId, onNodeChanged);
    listeners.removeOptionalMenuListener(onOptionalMenuSelected);
    currentIndex.dispose();
    list.clear();
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void onCursorChanged(BasicCursor cursor) {
    if (cursor is! EditingCursor) {
      hideMenu();
      return;
    }
    if (cursor.position is! RichTextNodePosition) {
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

  void onNodeChanged(EditorNode node) {
    if (node.id != nodeId) hideMenu();
    if (node is! RichTextNode) {
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
    final filterText = text.replaceFirst('/', '');
    List<MenuItemInfo> newList = [];
    for (var menu in widget.menuItems) {
      if (menu.text.toLowerCase().contains(filterText.toLowerCase())) newList.add(menu);
    }
    if (newList.isNotEmpty) {
      list = newList;
      refresh();
    } else {
      list.clear();
      refresh();
      countdownToHideMenu();
    }
    isCheckingText = false;
  }

  void countdownToHideMenu() {
    if (isCountingDown) return;
    isCountingDown = true;
    Future.delayed(Duration(seconds: 3), () {
      isCountingDown = false;
      if (list.isEmpty) hideMenu();
    });
  }

  void onOptionalMenuSelected(OptionalSelectedType type) {
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
        onItemSelected(current);
        break;
    }
  }

  void onItemSelected(MenuItemInfo current) {
    hideMenu();
    final c = operator.cursor;
    if (c is! EditingCursor) return;
    final node = operator.getNode(c.index);
    if (node.id != nodeId) return;
    if (node is! RichTextNode) return;
    final generator = current.generator;
    if (generator == null) return;
    final rearNode = node.rearPartNode(c.position as RichTextNodePosition);
    try {
      final newNode = generator.call(rearNode);
      operator.onOperation(Update(
          c.index, newNode, EditingCursor(c.index, newNode.beginPosition)));
    } on TryingToCreateLinkException {
      final frontNode = node.frontPartNode(c.position as RichTextNodePosition);

      manager.showLinkMenu(
          Overlay.of(context),
          LinkMenuInfo(
              SelectingNodeCursor(c.index, node.beginPosition,
                  c.position as RichTextNodePosition),
              offset.offset,
              nodeId,
              UrlInfo('', frontNode.text)),
          operator);
    }
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
                  elevation: 2,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Container(
                    height: info.size.height,
                    width: info.size.width,
                    margin: EdgeInsets.symmetric(vertical: 12),
                    child: ValueListenableBuilder(
                        valueListenable: currentIndex,
                        builder: (context, v, c) {
                          if (list.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('☕️...'),
                            );
                          }
                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 8),
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
        onTap: () => onItemSelected(current),
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
    final widgetSize = Size(220, 32.0 * max(list.length, 1));
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

List<MenuItemInfo> getDefaultMenus(BuildContext context) {
  if (!context.mounted) return [];
  final app = AppLocalizations.of(context);
  if (app == null) return [];
  return [
    MenuItemInfo.readable(app.basic),
    MenuItemInfo.normal(
        app.text, Icons.text_fields_rounded, _textColor, (n) => n),
    MenuItemInfo.normal(app.h1, Icons.title_rounded, _textColor,
        (n) => H1Node.from(n.spans, id: n.id, depth: n.depth)),
    MenuItemInfo.normal(app.h2, Icons.title_rounded, _textColor,
        (n) => H2Node.from(n.spans, id: n.id, depth: n.depth)),
    MenuItemInfo.normal(app.h3, Icons.title_rounded, _textColor,
        (n) => H3Node.from(n.spans, id: n.id, depth: n.depth)),
    MenuItemInfo.normal(app.orderedList, Icons.format_list_numbered_rounded,
        _textColor, (n) => OrderedNode.from(n.spans, id: n.id, depth: n.depth)),
    MenuItemInfo.normal(app.unorderedList, Icons.list_rounded, _textColor,
        (n) => UnorderedNode.from(n.spans, id: n.id, depth: n.depth)),
    MenuItemInfo.normal(
        app.codeBlock,
        Icons.code,
        _codeColor,
        (n) => CodeBlockNode.from(n.spans.map((e) => e.text).toList(),
            id: n.id, depth: n.depth)),
    MenuItemInfo.normal(app.quote, Icons.format_quote_rounded, _quoteColor,
        (n) => QuoteNode.from(n.spans, id: n.id, depth: n.depth)),
    MenuItemInfo.normal(app.horizontalLine, Icons.horizontal_rule_rounded,
        _dividerColor, (n) => DividerNode(id: n.id, depth: n.depth)),
    MenuItemInfo.normal(app.link, Icons.add_link_rounded, _linkColor,
        (n) => throw TryingToCreateLinkException()),
    MenuItemInfo.readable(app.commonlyUsed),
    MenuItemInfo.normal(app.taskList, Icons.task_rounded, _textColor,
        (n) => TodoNode.from(n.spans, id: n.id, depth: n.depth)),
    MenuItemInfo.normal(app.table, Icons.table_chart_rounded, _tableColor,
        (n) => TableNode.from([], [], id: n.id, depth: n.depth)),
  ];
}

const _textColor = Colors.brown;
const _codeColor = Colors.cyan;
const _linkColor = Colors.blue;
const _quoteColor = Colors.yellow;
const _tableColor = Colors.blueAccent;
const _dividerColor = Colors.orange;

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
