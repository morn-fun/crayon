import 'package:crayon/editor/node/basic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../command/modify.dart';
import '../../core/context.dart';
import '../../core/editor_controller.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic.dart';
import '../../cursor/node_position.dart';
import '../../node/rich_text/rich_text_span.dart';
import '../../shortcuts/styles.dart';

class LinkMenu extends StatefulWidget {
  final EditorContext editorContext;
  final MenuInfo info;
  final UrlWithPosition? urlWithPosition;

  const LinkMenu(this.editorContext, this.info,
      {super.key, this.urlWithPosition});

  @override
  State<LinkMenu> createState() => _LinkMenuState();
}

class _LinkMenuState extends State<LinkMenu> {
  EditorContext get editorContext => widget.editorContext;

  RichEditorController get controller => editorContext.controller;

  ListenerCollection get listeners => controller.listeners;

  MenuInfo get info => widget.info;

  bool enableCancel = false;

  late TextEditingController editingController;

  bool clickable = false;

  @override
  void initState() {
    final urlWithPosition = widget.urlWithPosition;
    editingController = TextEditingController(text: urlWithPosition?.url ?? '');
    enableCancel = urlWithPosition != null;
    clickable = isTextALink(editingController.text);
    listeners.addCursorChangedListener(_onCursorChanged);
    editingController.addListener(() {
      final v = isTextALink(editingController.text);
      if (clickable != v) {
        clickable = v;
        refresh();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    listeners.removeCursorChangedListener(_onCursorChanged);
    editingController.dispose();
    super.dispose();
  }

  void _onCursorChanged(BasicCursor cursor) {
    if (cursor is EditingCursor) {
      hideMenu();
      return;
    }
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
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (e) =>
                editorContext.updateEntryStatus(EntryStatus.onMenuHovering),
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
                    if (enableCancel)
                      Padding(
                        padding: EdgeInsets.only(left: 24),
                        child: IconButton(
                          icon: Icon(Icons.link_off_rounded),
                          onPressed: () {
                            final linkCursor = widget.urlWithPosition!.cursor;
                            final r = controller
                                .getNode(linkCursor.index)
                                .onSelect(SelectingData(
                                    SelectingPosition(
                                        linkCursor.begin, linkCursor.end),
                                    EventType.link,
                                    extras: StyleExtra(false, {})));
                            editorContext.execute(ModifyNodeWithoutChangeCursor(
                                linkCursor.index, r.node));
                            hideMenu();
                          },
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: OutlinedButton(
                        child: Text('Confirm'),
                        onPressed: clickable
                            ? () {
                                final text = editingController.text;
                                if (enableCancel) {
                                  final linkCursor =
                                      widget.urlWithPosition!.cursor;
                                  final r = controller
                                      .getNode(linkCursor.index)
                                      .onSelect(SelectingData(
                                          SelectingPosition(
                                              linkCursor.begin, linkCursor.end),
                                          EventType.link,
                                          extras:
                                              StyleExtra(true, {'url': text})));
                                  editorContext.execute(
                                      ModifyNodeWithoutChangeCursor(
                                          linkCursor.index, r.node));
                                } else {
                                  onStyleEvent(editorContext, RichTextTag.link,
                                      attributes: {'url': text});
                                }
                                hideMenu();
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          top: dy,
          left: dx,
        )
      ],
    );
  }
}

bool isTextALink(String text) =>
    RegExp(r'https?://(?:www\.)?[a-zA-Z0-9-]+(?:\.[a-zA-Z]{2,})+(?:/\S*)?')
        .hasMatch(text);

class LinkHover extends StatefulWidget {
  final PointerEnterEventListener? onEnter;

  final PointerExitEventListener? onExit;

  final VoidCallback? onTap;
  final LinkHoverBuilder builder;

  const LinkHover(
      {super.key,
      this.onEnter,
      this.onExit,
      this.onTap,
      required this.builder});

  @override
  State<LinkHover> createState() => _LinkHoverState();
}

class _LinkHoverState extends State<LinkHover> {
  bool hovered = false;

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) {
        widget.onEnter?.call(e);
        hovered = true;
        refresh();
      },
      onExit: (e) {
        widget.onExit?.call(e);
        hovered = false;
        refresh();
      },
      child: InkWell(
        onTap: widget.onTap,
        child: widget.builder.call(hovered),
      ),
    );
  }
}

typedef LinkHoverBuilder = Widget Function(bool hovered);
