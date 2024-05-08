import 'package:flutter/material.dart';

import '../cursor/basic.dart';
import '../widget/menu/link.dart';
import '../widget/menu/optional.dart';
import '../widget/menu/rich_text.dart';
import 'context.dart';
import 'editor_controller.dart';

class EntryManager {
  OverlayEntry? _showingEntry;
  MenuType? _lastShowingType;

  final ValueChanged<MenuType>? onMenuShowing;
  final ValueChanged<MenuType>? onMenuHide;

  EntryManager({this.onMenuShowing, this.onMenuHide});

  void removeEntry() {
    if (_showingEntry != null) {
      _showingEntry?.remove();
    }
    if (_lastShowingType != null) {
      onMenuHide?.call(_lastShowingType!);
    }
    _showingEntry = null;
    _lastShowingType = null;
  }

  void _notifyMenuShowing() {
    if (_lastShowingType != null && onMenuShowing != null) {
      onMenuShowing?.call(_lastShowingType!);
    }
  }

  void showOptionalMenu(
      EditingOffset offset, OverlayState state, EditorContext context) async {
    removeEntry();
    _lastShowingType = MenuType.optional;
    _showingEntry = OverlayEntry(
        builder: (_) => OptionalMenu(
              offset: offset,
              nodeContext: context,
              listeners: context.listeners,
            ));
    state.insert(_showingEntry!);
    _notifyMenuShowing();
  }

  void showTextMenu(OverlayState state, MenuInfo info, LayerLink link,
      EditorContext context) {
    removeEntry();
    _lastShowingType = MenuType.text;
    _showingEntry = OverlayEntry(
        builder: (_) => CompositedTransformFollower(
              child: TextMenu(context, info, link, context.listeners),
              showWhenUnlinked: false,
              link: link,
            ));
    state.insert(_showingEntry!);
    _notifyMenuShowing();
  }

  void showLinkMenu(
      OverlayState state, MenuInfo info, LayerLink link, EditorContext context,
      {UrlWithPosition? urlWithPosition}) {
    removeEntry();
    _lastShowingType = MenuType.text;
    _showingEntry = OverlayEntry(
        builder: (_) => CompositedTransformFollower(
              child: LinkMenu(context, info, urlWithPosition: urlWithPosition),
              showWhenUnlinked: false,
              link: link,
            ));
    state.insert(_showingEntry!);
    _notifyMenuShowing();
  }

  void dispose() {
    removeEntry();
  }
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

enum MenuType { optional, link, text }

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
