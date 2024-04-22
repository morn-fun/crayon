import 'package:flutter/material.dart';

import '../../core/context.dart';

class ShareEditorContextWidget extends InheritedWidget {
  ShareEditorContextWidget({
    Key? key,
    required this.context,
    required Widget child,
  }) : super(key: key, child: child);

  final EditorContext context;

  static ShareEditorContextWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ShareEditorContextWidget>();
  }

  @override
  bool updateShouldNotify(ShareEditorContextWidget oldWidget) {
    return oldWidget.context != context;
  }
}
