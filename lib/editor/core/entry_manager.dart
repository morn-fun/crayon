import 'package:flutter/material.dart';

import '../widget/menu/link_menu.dart';
import '../widget/menu/optional_menu.dart';
import '../widget/menu/text_menu.dart';
import 'context.dart';

class EntryManager {
  OverlayEntry? showingEntry;
  EntryStatus _status = EntryStatus.idle;

  final Function(EntryStatus status) onStatusChanged;

  EntryManager(this.onStatusChanged);

  void removeEntry() {
    showingEntry?.remove();
    showingEntry = null;
  }

  void hideMenu() {
    removeEntry();
    updateStatus(EntryStatus.idle);
  }

  void showOptionalMenu(
      Offset offset, OverlayState state, EditorContext context) async {
    if (_status != EntryStatus.readyToShowingOptionalMenu) return;
    removeEntry();
    showingEntry = OverlayEntry(
        builder: (_) => OptionalMenu(offset: offset, editorContext: context));
    state.insert(showingEntry!);
    updateStatus(EntryStatus.showingOptionalMenu);
  }

  void hideOptionalMenu() {
    if (!isOptionalMenuShowing) return;
    hideMenu();
  }

  void showTextMenu(OverlayState state, MenuInfo info, LayerLink link,
      EditorContext context) {
    if (_status != EntryStatus.readyToShowingTextMenu) return;
    removeEntry();
    showingEntry = OverlayEntry(
        builder: (_) => CompositedTransformFollower(
              child: TextMenu(context, info, link),
              showWhenUnlinked: false,
              link: link,
            ));
    state.insert(showingEntry!);
    updateStatus(EntryStatus.showingTextMenu);
  }

  void hideTextMenu() {
    if (!isTextMenuShowing) return;
    hideMenu();
  }

  void showLinkMenu(
      OverlayState state, MenuInfo info, LayerLink link, EditorContext context,
      {String? initialUrl}) {
    if (_status != EntryStatus.readyToShowingLinkMenu) return;
    removeEntry();
    showingEntry = OverlayEntry(
        builder: (_) => CompositedTransformFollower(
              child: LinkMenu(context, info, initialUrl: initialUrl),
              showWhenUnlinked: false,
              link: link,
            ));
    state.insert(showingEntry!);
    updateStatus(EntryStatus.showingLinkMenu);
  }

  void hideLinkMenu() {
    if (!isLinkMenuShowing) return;
    hideMenu();
  }

  void dispose() {
    removeEntry();
  }

  void updateStatus(EntryStatus status) {
    if (_status == status) return;
    _status = status;
    onStatusChanged.call(status);
  }

  bool get isOptionalMenuShowing => _status == EntryStatus.showingOptionalMenu;

  bool get isTextMenuShowing => _status == EntryStatus.showingTextMenu;

  bool get isLinkMenuShowing => _status == EntryStatus.showingLinkMenu;

  bool get isShowing => _status != EntryStatus.idle;

  EntryStatus get status => _status;
}

class MenuInfo {
  final Offset offset;
  final String nodeId;

  MenuInfo(this.offset, this.nodeId);

  MenuInfo.zero()
      : offset = Offset.zero,
        nodeId = '';
}

enum EntryStatus {
  idle,
  readyToShowingOptionalMenu,
  showingOptionalMenu,
  readyToShowingTextMenu,
  showingTextMenu,
  readyToShowingLinkMenu,
  showingLinkMenu,
}
