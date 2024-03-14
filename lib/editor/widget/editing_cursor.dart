import 'dart:async';

import 'package:flutter/material.dart';

class EditingCursorWidget extends StatefulWidget {
  final double cursorHeight;
  final Color cursorColor;

  const EditingCursorWidget(
      {super.key, required this.cursorHeight, required this.cursorColor});

  @override
  State<EditingCursorWidget> createState() => _EditingCursorWidgetState();
}

class _EditingCursorWidgetState extends State<EditingCursorWidget> {
  var visible = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      visible = !visible;
      refresh();
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.cursorHeight,
      width: 1,
      color: visible ? widget.cursorColor : Colors.transparent,
    );
  }
}
