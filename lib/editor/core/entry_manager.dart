import 'package:flutter/material.dart';

import '../cursor/basic.dart';
import '../widget/menu/link.dart';
import '../widget/menu/optional.dart';
import '../widget/menu/text.dart';
import 'context.dart';
import 'editor_controller.dart';

class EntryManager {
  OverlayEntry? _showingEntry;
  MenuType? _lastShowingType;

  final ValueChanged<MenuType>? _onMenuShowing;
  final ValueChanged<MenuType>? _onMenuHide;

  EntryManager(this._onMenuShowing, this._onMenuHide);

  void removeEntry() {
    if (_showingEntry != null) {
      _showingEntry?.remove();
    }
    if (_lastShowingType != null) {
      _onMenuHide?.call(_lastShowingType!);
    }
    _showingEntry = null;
    _lastShowingType = null;
  }

  void _notifyMenuShowing() {
    if (_lastShowingType != null && _onMenuShowing != null) {
      _onMenuShowing?.call(_lastShowingType!);
    }
  }

  void showOptionalMenu(
      EditingOffset offset, OverlayState state, ValueGetter<NodeContext> contextGetter) async {
    removeEntry();
    _lastShowingType = MenuType.optional;
    _showingEntry =
        OverlayEntry(builder: (_) => OptionalMenu(offset, contextGetter, this));
    state.insert(_showingEntry!);
    _notifyMenuShowing();
  }

  void showTextMenu(OverlayState state, MenuInfo info,
      ValueGetter<NodeContext> contextGetter) {
    removeEntry();
    _lastShowingType = MenuType.text;
    _showingEntry = OverlayEntry(
        builder: (_) => CompositedTransformFollower(
              child: TextMenu(contextGetter, info, this),
              showWhenUnlinked: false,
              link: info.layerLink,
            ));
    state.insert(_showingEntry!);
    _notifyMenuShowing();
  }

  void showLinkMenu(
      OverlayState state, LinkMenuInfo linkMenuInfo, ValueGetter<NodeContext> contextGetter) {
    removeEntry();
    _lastShowingType = MenuType.text;
    _showingEntry = OverlayEntry(
        builder: (_) => CompositedTransformFollower(
              child: LinkMenu(contextGetter, linkMenuInfo.menuInfo, this,
                  urlWithPosition: linkMenuInfo.urlWithPosition),
              showWhenUnlinked: false,
              link: linkMenuInfo.link,
            ));
    state.insert(_showingEntry!);
    _notifyMenuShowing();
  }

  void dispose() {
    removeEntry();
  }

  MenuType? get showingType => _lastShowingType;
}

class MenuInfo {
  final Offset offset;
  final String nodeId;
  final double lineHeight;
  final LayerLink layerLink;

  MenuInfo(this.offset, this.nodeId, this.lineHeight, this.layerLink);

  MenuInfo.zero()
      : offset = Offset.zero,
        lineHeight = 0,
        nodeId = '',
        layerLink = LayerLink();

  @override
  String toString() {
    return 'MenuInfo{offset: $offset, nodeId: $nodeId, lineHeight: $lineHeight}';
  }
}

enum MenuType { optional, link, text }

class LinkMenuInfo {
  final MenuInfo menuInfo;
  final UrlWithPosition? urlWithPosition;

  LayerLink get link => menuInfo.layerLink;

  LinkMenuInfo(this.menuInfo, this.urlWithPosition);

  @override
  String toString() {
    return 'LinkMenuInfo{menuInfo: $menuInfo, urlWithPosition: $urlWithPosition}';
  }
}

class UrlWithPosition {
  final String url;
  final SelectingNodeCursor cursor;

  UrlWithPosition(this.url, this.cursor);

  @override
  String toString() {
    return 'UrlWithPosition{url: $url, cursor: $cursor}';
  }
}
