import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../command/modification.dart';
import '../../core/context.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic.dart';
import '../../cursor/rich_text.dart';
import '../../node/basic.dart';
import '../../node/rich_text/rich_text.dart';
import '../../node/rich_text/rich_text_span.dart';
import '../../shortcuts/styles.dart';

class LinkMenu extends StatefulWidget {
  final NodesOperator operator;
  final LinkMenuInfo info;
  final EntryManager manager;

  const LinkMenu(this.operator, this.info, this.manager, {super.key});

  @override
  State<LinkMenu> createState() => _LinkMenuState();
}

class _LinkMenuState extends State<LinkMenu> {
  NodesOperator get operator => widget.operator;

  ListenerCollection get listeners => operator.listeners;

  LinkMenuInfo get linkMenuInfo => widget.info;

  EntryManager get manager => widget.manager;

  UrlInfo get urlInfo => linkMenuInfo.urlInfo;

  SelectingNodeCursor<RichTextNodePosition> get cursor => linkMenuInfo.cursor;

  late TextEditingController linkController;
  late TextEditingController titleController;

  bool clickable = false;

  @override
  void initState() {
    final urlInfo = this.urlInfo;
    linkController = TextEditingController(text: urlInfo.url);
    titleController = TextEditingController(text: urlInfo.alias);
    clickable = isTextALink(linkController.text);
    listeners.addCursorChangedListener(onCursorChanged);
    linkController.addListener(() {
      final v = isTextALink(linkController.text);
      if (clickable != v) {
        clickable = v;
        refresh();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    listeners.removeCursorChangedListener(onCursorChanged);
    linkController.dispose();
    titleController.dispose();
    super.dispose();
  }

  void onCursorChanged(BasicCursor cursor) {
    if (cursor is EditingCursor) {
      hideMenu();
      return;
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void hideMenu() => manager.removeEntry();

  @override
  Widget build(BuildContext context) {
    double dy = linkMenuInfo.offset.dy;
    double dx = linkMenuInfo.offset.dx;
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
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: SizedBox(
                          width: 280,
                          height: 32,
                          child: TextField(
                            controller: titleController,
                            cursorHeight: 14,
                            cursorColor: Colors.blueAccent,
                            decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.blueAccent)),
                                border: const OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.fromLTRB(4, 0, 4, 0)),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SizedBox(
                              width: 280,
                              height: 32,
                              child: TextField(
                                controller: linkController,
                                cursorHeight: 14,
                                cursorColor: Colors.blueAccent,
                                decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.blueAccent)),
                                    border: const OutlineInputBorder(),
                                    contentPadding:
                                        EdgeInsets.fromLTRB(4, 0, 4, 0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: OutlinedButton(
                              child: Text('Confirm'),
                              onPressed: clickable ? () => onConfirm() : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              top: dy,
              left: dx,
            )
          ],
        ),
      ),
    );
  }

  void onConfirm() {
    final url = linkController.text;
    final alias = titleController.text;
    final linkCursor = cursor;
    final attr = {
      'url': url,
      'alias': alias,
    };
    final r = operator.getNode(linkCursor.index).onSelect(SelectingData(
        linkCursor, EventType.link, operator,
        extras: StyleExtra(false, attr)));
    operator.execute(ModifyNode(NodeWithCursor(r.node, r.cursor)));
    hideMenu();
  }
}

bool isTextALink(String text) =>
    RegExp(r'https?://(?:www\.)?[a-zA-Z0-9-]+(?:\.[a-zA-Z]{2,})+(?:/\S*)?')
        .hasMatch(text);

class LinkHover extends StatelessWidget {
  final ValueChanged<LinkMenuInfo>? onEdit;
  final ValueChanged<SelectingNodeCursor>? onCancel;
  final ValueChanged<RichTextSpan>? onTap;
  final RichTextNode node;
  final TextPainter painter;
  final int widgetIndex;
  final LayerLink layerLink;
  final ValueGetter<bool> enableToShow;

  const LinkHover({
    super.key,
    this.onEdit,
    this.onCancel,
    this.onTap,
    required this.node,
    required this.painter,
    required this.layerLink,
    required this.widgetIndex,
    required this.enableToShow,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    for (var i = 0; i < node.spans.length; ++i) {
      final span = node.spans[i];
      if (!span.tags.contains(RichTextTag.link.name)) continue;
      final boxList = painter.getBoxesForSelection(
          TextSelection(baseOffset: span.offset, extentOffset: span.endOffset));
      if (boxList.isEmpty) continue;
      final cursor = SelectingNodeCursor(widgetIndex,
          RichTextNodePosition(i, 0), RichTextNodePosition(i, span.textLength));
      children.add(LinkOverlay(
        span,
        painter,
        onTap: () => onTap?.call(span),
        onLinkEdit: (o) {
          final url = span.attributes['url'] ?? '';
          final alias = span.attributes['alias'] ?? '';
          onEdit?.call(LinkMenuInfo(cursor, o, node.id, UrlInfo(url, alias)));
        },
        onLinkCanceled: () {
          onCancel?.call(cursor);
        },
        enableToShow: enableToShow,
      ));
    }
    return Stack(children: children);
  }
}

class LinkOverlay extends StatefulWidget {
  final RichTextSpan span;
  final TextPainter painter;
  final VoidCallback? onTap;
  final VoidCallback? onLinkCanceled;
  final ValueChanged<Offset>? onLinkEdit;
  final ValueGetter<bool> enableToShow;

  const LinkOverlay(
    this.span,
    this.painter, {
    super.key,
    this.onTap,
    this.onLinkCanceled,
    this.onLinkEdit,
    required this.enableToShow,
  });

  @override
  State<LinkOverlay> createState() => _LinkOverlayState();
}

class _LinkOverlayState extends State<LinkOverlay> {
  TextPainter get painter => widget.painter;

  RichTextSpan get span => widget.span;

  int hoveredNum = 0;

  OverlayPortalController controller = OverlayPortalController();

  Timer? timer;

  final key = GlobalKey();

  @override
  void dispose() {
    if (controller.isShowing) controller.hide();
    cancelTimer();
    super.dispose();
  }

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  @override
  Widget build(BuildContext context) {
    final boxList = painter.getBoxesForSelection(
        TextSelection(baseOffset: span.offset, extentOffset: span.endOffset));
    if (boxList.isEmpty) return Container();
    return OverlayPortal(
      controller: controller,
      overlayChildBuilder: (ctx) {
        final box = renderBox;
        if (box == null) return SizedBox.shrink();
        final first = boxList.first.toRect().bottomLeft;
        final last = boxList.last.toRect().bottomRight;
        final screenSize = MediaQuery.of(ctx).size;
        final x = (last.dx + first.dx) / 2;
        final y = max(max(0.0, first.dy), min(screenSize.height, last.dy));
        final globalOffset = box.localToGlobal(Offset(x, y));
        return Positioned(
          left: globalOffset.dx,
          top: globalOffset.dy,
          child: MouseRegion(
            onEnter: (v) {
              hoveredNum++;
            },
            onExit: (v) {
              if (hoveredNum > 0) {
                hoveredNum--;
              }
              if (hoveredNum == 0) {
                createExitTimer();
              }
            },
            child: Container(
                width: 350,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            widget.onLinkEdit?.call(globalOffset);
                            hide();
                          },
                          icon: Icon(Icons.edit_note_rounded)),
                      IconButton(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: url));
                            hide();
                          },
                          icon: Icon(Icons.copy_all_rounded)),
                      IconButton(
                          onPressed: () {
                            widget.onLinkCanceled?.call();
                            hide();
                          },
                          icon: Icon(Icons.link_off_rounded)),
                    ]),
                  ),
                )),
          ),
        );
      },
      child: Stack(
        key: key,
        children: List.generate(boxList.length, (i) {
          final box = boxList[i];
          final width = box.right - box.left, height = box.bottom - box.top;
          return Positioned(
            child: SizedBox(
              width: width,
              height: height,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (v) {
                  hoveredNum++;
                  show();
                },
                onExit: (v) {
                  if (hoveredNum > 0) {
                    hoveredNum--;
                  }
                  if (hoveredNum == 0) {
                    createExitTimer();
                  }
                },
                child: GestureDetector(onTap: () {
                  widget.onTap?.call();
                }),
              ),
            ),
            left: box.left,
            top: box.top,
          );
        }),
      ),
    );
  }

  String get url => widget.span.attributes['url'] ?? '';

  void show() {
    if (!widget.enableToShow.call()) return;
    if (!controller.isShowing) controller.show();
  }

  void hide() {
    if (controller.isShowing) controller.hide();
    hoveredNum = 0;
  }

  void cancelTimer() {
    timer?.cancel();
    timer = null;
  }

  void createExitTimer() {
    if (timer != null) return;
    timer = Timer(Duration(milliseconds: 200), () {
      cancelTimer();
      if (hoveredNum <= 0) hide();
    });
  }
}
