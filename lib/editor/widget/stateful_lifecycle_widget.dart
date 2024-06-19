import 'package:flutter/material.dart';

class StatefulLifecycleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onInit;
  final VoidCallback? onDispose;

  const StatefulLifecycleWidget(
      {super.key, required this.child, this.onInit, this.onDispose});

  @override
  State<StatefulLifecycleWidget> createState() =>
      _StatefulLifecycleWidgetState();
}

class _StatefulLifecycleWidgetState extends State<StatefulLifecycleWidget> {
  @override
  void initState() {
    widget.onInit?.call();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.onDispose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
