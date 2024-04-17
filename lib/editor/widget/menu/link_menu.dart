import 'package:flutter/material.dart';

import '../../core/context.dart';
import '../../core/controller.dart';
import '../../core/entry_manager.dart';
import '../../core/listener_collection.dart';
import '../../cursor/basic_cursor.dart';
import '../../node/rich_text_node/rich_text_span.dart';
import '../../shortcuts/styles.dart';

class LinkMenu extends StatefulWidget {
  final EditorContext editorContext;
  final MenuInfo info;
  final String? initialUrl;

  const LinkMenu(this.editorContext, this.info, {super.key, this.initialUrl});

  @override
  State<LinkMenu> createState() => _LinkMenuState();
}

class _LinkMenuState extends State<LinkMenu> {
  EditorContext get editorContext => widget.editorContext;

  RichEditorController get controller => editorContext.controller;

  ListenerCollection get listeners => controller.listeners;

  MenuInfo get info => widget.info;

  String get initialUrl => widget.initialUrl ?? '';

  late TextEditingController editingController =
      TextEditingController(text: initialUrl);

  bool clickable = false;

  @override
  void initState() {
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
                              borderSide: BorderSide(color: Colors.blueAccent)),
                          border: const OutlineInputBorder(),
                          contentPadding: EdgeInsets.fromLTRB(4, 0, 4, 0)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 24),
                    child: OutlinedButton(
                      child: Text('Confirm'),
                      onPressed: clickable
                          ? () {
                              final text = editingController.text;
                              onStyleEvent(editorContext, RichTextTag.link,
                                  attributes: {'url': text});
                              hideMenu();
                            }
                          : null,
                    ),
                  )
                ],
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
