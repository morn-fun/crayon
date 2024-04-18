import 'package:flutter/material.dart';

import '../cursor/basic_cursor.dart';
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
      {UrlWithPosition? urlWithPosition}) {
    if (_status != EntryStatus.readyToShowingLinkMenu) return;
    removeEntry();
    updateStatus(EntryStatus.showingLinkMenu);
    showingEntry = OverlayEntry(
        builder: (_) => CompositedTransformFollower(
              child: LinkMenu(context, info, urlWithPosition: urlWithPosition),
              showWhenUnlinked: false,
              link: link,
            ));
    state.insert(showingEntry!);
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
  final double lineHeight;

  MenuInfo(this.offset, this.nodeId, this.lineHeight);

  MenuInfo.zero()
      : offset = Offset.zero,
        lineHeight = 0,
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
  onMenuHovering,
}

abstract class EntryShower {
  void show(OverlayState state, EditorContext context);
}

class OptionalEntryShower implements EntryShower {
  final Offset offset;

  OptionalEntryShower(this.offset);

  @override
  void show(OverlayState state, EditorContext context) =>
      context.showOptionalMenu(offset, state);
}

class TextMenuEntryShower implements EntryShower {
  final MenuInfo menuInfo;
  final LayerLink layerLink;

  TextMenuEntryShower(this.menuInfo, this.layerLink);

  @override
  void show(OverlayState state, EditorContext context) =>
      context.showTextMenu(state, menuInfo, layerLink);
}

class LinkEntryShower implements EntryShower {
  final MenuInfo menuInfo;
  final LayerLink layerLink;
  final UrlWithPosition? urlWithPosition;

  LinkEntryShower(this.menuInfo, this.layerLink, {this.urlWithPosition});

  @override
  void show(OverlayState state, EditorContext context) =>
      context.showLinkMenu(state, menuInfo, layerLink,
          urlWithPosition: urlWithPosition);
}

class UrlWithPosition {
  final String url;
  final SelectingNodeCursor cursor;

  UrlWithPosition(this.url, this.cursor);
}
