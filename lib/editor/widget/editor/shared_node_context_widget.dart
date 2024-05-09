import 'package:flutter/material.dart';

import '../../core/context.dart';

class ShareNodeContextWidget extends InheritedWidget {
  ShareNodeContextWidget({
    Key? key,
    required this.context,
    required Widget child,
  }) : super(key: key, child: child);

  final NodeContext context;

  static ShareNodeContextWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ShareNodeContextWidget>();
  }

  @override
  bool updateShouldNotify(ShareNodeContextWidget oldWidget) {
    return oldWidget.context != context;
  }
}
