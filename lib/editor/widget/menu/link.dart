import 'package:crayon/editor/extension/painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../command/modification.dart';
import '../../core/context.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
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

  MenuInfo get info => linkMenuInfo.menuInfo;

  LinkMenuInfo get linkMenuInfo => widget.info;

  bool get hovered => linkMenuInfo.hovered;

  EntryManager get manager => widget.manager;

  UrlInfo? get urlInfo => linkMenuInfo.urlInfo;

  SelectingNodeCursor<RichTextNodePosition> get cursor => linkMenuInfo.cursor;

  late TextEditingController editingController;

  bool clickable = false;

  bool selfHovered = false;

  @override
  void initState() {
    final urlInfo = this.urlInfo;
    editingController = TextEditingController(text: urlInfo?.url ?? '');
    clickable = isTextALink(editingController.text);
    listeners.addCursorChangedListener(onCursorChanged);
    editingController.addListener(() {
      final v = isTextALink(editingController.text);
      if (clickable != v) {
        clickable = v;
        refresh();
      }
    });
    tryToHide();
    super.initState();
  }

  @override
  void dispose() {
    listeners.removeCursorChangedListener(onCursorChanged);
    editingController.dispose();
    super.dispose();
  }

  void onCursorChanged(BasicCursor cursor) {
    if (cursor is EditingCursor) {
      hideMenu();
      return;
    }
  }

  void tryToHide(){
    Future.delayed(Duration(milliseconds: 100), (){
      if(!mounted) return;
      if(!hovered && !selfHovered) {
        hideMenu();
      }
      tryToHide();
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
    return Stack(
      children: [
        Positioned(
          child: MouseRegion(
            onEnter: (e) => selfHovered = true,
            onExit: (e) => hideMenu(),
            child: Card(
              elevation: 10,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 280,
                      height: 32,
                      child: TextField(
                        controller: editingController,
                        cursorHeight: 14,
                        cursorColor: Colors.blueAccent,
                        decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.blueAccent)),
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.fromLTRB(4, 0, 4, 0)),
                      ),
                    ),
                    if (urlInfo != null)
                      Padding(
                        padding: EdgeInsets.only(left: 24),
                        child: IconButton(
                          icon: Icon(Icons.link_off_rounded),
                          onPressed: () {
                            final linkCursor = cursor;
                            final r = operator
                                .getNode(linkCursor.index)
                                .onSelect(SelectingData(
                                    linkCursor, EventType.link, operator,
                                    extras: StyleExtra(true, {})));
                            operator.execute(ModifyNodeWithoutChangeCursor(
                                linkCursor.index, r.node));
                            hideMenu();
                          },
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: OutlinedButton(
                        child: Text('Confirm'),
                        onPressed: clickable ? () => onConfirm() : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          top: dy + 6,
          left: dx,
        )
      ],
    );
  }

  void onConfirm() {
    final text = editingController.text;
    if (urlInfo != null) {
      final linkCursor = cursor;
      final r = operator.getNode(linkCursor.index).onSelect(SelectingData(
          linkCursor, EventType.link, operator,
          extras: StyleExtra(false, {'url': text})));
      operator.execute(ModifyNodeWithoutChangeCursor(linkCursor.index, r.node));
    } else {
      onStyleEvent(operator, RichTextTag.link, operator.cursor,
          attributes: {'url': text});
    }
    hideMenu();
  }
}

bool isTextALink(String text) =>
    RegExp(r'https?://(?:www\.)?[a-zA-Z0-9-]+(?:\.[a-zA-Z]{2,})+(?:/\S*)?')
        .hasMatch(text);

class LinkHover extends StatefulWidget {
  final OnLinkWidgetEnter? onEnter;
  final PointerExitEventListener? onExit;
  final ValueChanged<RichTextSpan>? onTap;
  final int nodeIndex;
  final RichTextNode node;
  final TextPainter painter;

  const LinkHover({
    super.key,
    this.onEnter,
    this.onExit,
    this.onTap,
    required this.node,
    required this.nodeIndex,
    required this.painter,
  });

  @override
  State<LinkHover> createState() => _LinkHoverState();
}

class _LinkHoverState extends State<LinkHover> {
  final Map<String, bool> url2hovered = {};

  TextPainter get painter => widget.painter;

  RichTextNode get node => widget.node;

  int get nodeIndex => widget.nodeIndex;

  @override
  void initState() {
    for (var span in node.spans) {
      final url = span.attributes['url'] ?? '';
      url2hovered[url] = false;
    }
    super.initState();
  }

  @override
  void dispose() {
    url2hovered.clear();
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stacks = [];
    for (var i = 0; i < node.spans.length; ++i) {
      final span = node.spans[i];
      if (!span.tags.contains(RichTextTag.link.name)) continue;
      List<Widget> children = [];
      final url = span.attributes['url'] ?? '';
      final boxList = painter.getBoxesForSelection(
          TextSelection(baseOffset: span.offset, extentOffset: span.endOffset));
      Map<int, double> baseline2MaxHeight =
          painter.baseline2MaxHeightMap(boxList);
      final selectingPosition = SelectingNodeCursor(nodeIndex,
          RichTextNodePosition(i, 0), RichTextNodePosition(i, span.textLength));
      final hovered = url2hovered[url] ?? false;
      final left = boxList.first.left;
      var top = baseline2MaxHeight[0];
      for (var box in boxList) {
        final baseline = ((box.bottom + box.top) / 2).round();
        final height = baseline2MaxHeight[baseline] ?? (box.bottom - box.top);
        final child = Padding(
            padding: EdgeInsets.only(top: baseline - height / 2),
            child: GestureDetector(
              onTap: () => widget.onTap?.call(span),
              child: Container(
                width: box.right - box.left,
                height: height,
                decoration: hovered
                    ? BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.blueAccent)))
                    : null,
              ),
            ));
        children.add(child);
      }
      stacks.add(Positioned(
        left: left, top: top,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (e) {
            final v = url2hovered[url] ?? false;
            logger.i('onEnter:$v');
            if (!v) {
              url2hovered[url] = true;
              widget.onEnter?.call(e.position, span, selectingPosition);
              refresh();
            }
          },
          onExit: (e) {
            final v = url2hovered[url] ?? false;
            logger.i('onExit:$v');
            if (v) {
              url2hovered[url] = false;
              widget.onExit?.call(e);
              refresh();
            }
          },
          child:
              Row(children: children,),
        ),
      ));
    }
    return Stack(children: stacks);
  }
}

typedef LinkHoverBuilder = Widget Function(bool hovered);
