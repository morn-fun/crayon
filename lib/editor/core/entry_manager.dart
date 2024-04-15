import 'package:flutter/material.dart';

import '../widget/menu/optional_menu.dart';
import '../widget/menu/text_menu.dart';
import 'context.dart';
import 'listener_collection.dart';

class EntryManager {
  OverlayEntry? _optionalMenuEntry;
  OverlayEntry? _textMenu;
  OverlayEntry? _linkMenuEntry;
  EntryStatus _status = EntryStatus.idle;
  TextMenuInfo _lastTextMenuInfo = TextMenuInfo.zero();

  void showOptionalMenu(
      Offset offset, OverlayState state, EditorContext context) async {
    if (isShowing) return;
    updateStatus(EntryStatus.showingOptionalMenu, context.listeners);
    _optionalMenuEntry = OverlayEntry(
        builder: (_) => OptionalMenu(offset: offset, editorContext: context));
    state.insert(_optionalMenuEntry!);
  }

  void showTextMenu(OverlayState state, TextMenuInfo? info, LayerLink link,
      EditorContext context) {
    if (isShowing) return;
    _removeEntry(_textMenu);
    _textMenu = null;
    final currentInfo = info ?? _lastTextMenuInfo;
    updateStatus(EntryStatus.showingTextMenu, context.listeners);
    _lastTextMenuInfo = currentInfo;
    _textMenu = OverlayEntry(
        builder: (_) => CompositedTransformFollower(
              child: TextMenu( context, currentInfo),
              showWhenUnlinked: false,
              link: link,
            ));
    state.insert(_textMenu!);
  }

  void removeOptionalMenu(ListenerCollection listeners) {
    if (isOptionalMenuShowing) updateStatus(EntryStatus.idle, listeners);
    _removeEntry(_optionalMenuEntry);
    _optionalMenuEntry = null;
  }

  void removeTextMenu(ListenerCollection listeners) {
    updateStatus(EntryStatus.idle, listeners);
    _removeEntry(_textMenu);
    _textMenu = null;
    _lastTextMenuInfo = TextMenuInfo.zero();
  }

  void hideTextMenu(ListenerCollection listeners) {
    if (isTextMenuShowing) {
      updateStatus(EntryStatus.showingTextMenuInvisible, listeners);
    }
    _removeEntry(_textMenu);
    _textMenu = null;
  }

  void dispose() {
    _removeEntry(_optionalMenuEntry);
    _removeEntry(_textMenu);
    _removeEntry(_linkMenuEntry);
    _optionalMenuEntry = null;
    _textMenu = null;
    _linkMenuEntry = null;
  }

  void _removeEntry(OverlayEntry? entry) {
    entry?.remove();
    entry?.dispose();
  }

  void updateStatus(EntryStatus status, ListenerCollection listeners) {
    if (_status == status) return;
    _status = status;
    listeners.notifyEntryStatus(status);
  }

  bool get isOptionalMenuShowing => _status == EntryStatus.showingOptionalMenu;

  bool get isTextMenuShowing => _status == EntryStatus.showingTextMenu;

  bool get isShowing => isOptionalMenuShowing || isTextMenuShowing;

  EntryStatus get status => _status;

  TextMenuInfo get lastTextMenuInfo => _lastTextMenuInfo;
}

class TextMenuInfo {
  final Offset offset;
  final String nodeId;

  TextMenuInfo(this.offset, this.nodeId);

  TextMenuInfo.zero()
      : offset = Offset.zero,
        nodeId = '';
}

enum EntryStatus {
  idle,
  readyForOptionalMenu,
  showingOptionalMenu,
  readyForTextMenu,
  showingTextMenu,
  showingTextMenuInvisible,
}
