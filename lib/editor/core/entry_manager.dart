import '../../../editor/cursor/rich_text.dart';
import 'package:flutter/material.dart';

import '../cursor/basic.dart';
import '../widget/menu/link.dart';
import '../widget/menu/optional.dart';
import '../widget/menu/text.dart';
import 'context.dart';
import 'editor_controller.dart';
import 'shortcuts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EntryManager {
  OverlayEntry? _showingEntry;
  MenuType? _lastShowingType;
  Type? _lastShowingContextType;

  final ValueChanged<MenuType>? _onMenuShowing;
  final ValueChanged<MenuType>? _onMenuHide;

  EntryManager(this._onMenuShowing, this._onMenuHide);

  void removeEntry() {
    _showingEntry?.remove();
    if (_lastShowingType != null) {
      _onMenuHide?.call(_lastShowingType!);
    }
    _showingEntry = null;
    _lastShowingType = null;
    _lastShowingContextType = null;
  }

  void _notifyMenuShowing() {
    if (_lastShowingType != null && _onMenuShowing != null) {
      _onMenuShowing?.call(_lastShowingType!);
    }
  }

  void showOptionalMenu(EditingOffset offset, OverlayState state,
          NodesOperator operator) async =>
      _showMenu(state, MenuType.optional, operator.runtimeType,
          OverlayEntry(builder: (ctx) {
        final menus = getDefaultMenus(ctx);
        if (operator is TableCellNodeContext) {
          menus.removeWhere((e) => e.text == AppLocalizations.of(ctx)?.table);
        }
        return OptionalMenu(offset, operator, this, menus);
      }));

  void showTextMenu(
          OverlayState state, MenuInfo info, NodesOperator operator) =>
      _showMenu(
          state,
          MenuType.text,
          operator.runtimeType,
          OverlayEntry(
              builder: (_) => CompositedTransformFollower(
                    child: TextMenu(operator, info, this),
                    showWhenUnlinked: false,
                    link: info.layerLink,
                  )));

  void showLinkMenu(OverlayState state, LinkMenuInfo linkMenuInfo,
          NodesOperator operator) =>
      _showMenu(state, MenuType.link, operator.runtimeType,
          OverlayEntry(builder: (_) => LinkMenu(operator, linkMenuInfo, this)));

  void _showMenu(OverlayState state, MenuType type, Type operatorType,
      OverlayEntry entry) {
    removeEntry();
    _lastShowingType = type;
    _lastShowingContextType = operatorType;
    _showingEntry = entry;
    state.insert(entry);
    _notifyMenuShowing();
  }

  void dispose() {
    removeEntry();
  }

  MenuType? get showingType => _lastShowingType;

  Type? get lastShowingContextType => _lastShowingContextType;
}

class MenuInfo {
  final Offset offset;
  final Offset globalOffset;
  final String nodeId;
  final LayerLink layerLink;

  MenuInfo(this.offset, this.globalOffset, this.nodeId, this.layerLink);

  MenuInfo.zero()
      : offset = Offset.zero,
        globalOffset = Offset.zero,
        nodeId = '',
        layerLink = LayerLink();

  @override
  String toString() {
    return 'MenuInfo{offset: $offset, globalOffset: $globalOffset, nodeId: $nodeId, layerLink: $layerLink}';
  }
}

enum MenuType { optional, codeLanguage, link, text }

class LinkMenuInfo {
  final UrlInfo urlInfo;
  final Offset offset;
  final String nodeId;
  final SelectingNodeCursor<RichTextNodePosition> cursor;

  LinkMenuInfo(this.cursor, this.offset, this.nodeId, this.urlInfo);

  @override
  String toString() {
    return 'LinkMenuInfo{urlInfo: $urlInfo, offset: $offset, nodeId: $nodeId, cursor: $cursor}';
  }
}

class UrlInfo {
  final String url;
  final String alias;

  UrlInfo(
    this.url,
    this.alias,
  );

  @override
  String toString() {
    return 'UrlInfo{url: $url, alias: $alias}';
  }
}

final menuType2Shortcuts = {
  MenuType.optional: optionalMenuShortcuts,
  MenuType.codeLanguage: arrowShortcuts,
  MenuType.link: linkMenuShortcuts,
};
