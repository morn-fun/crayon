import 'package:flutter/material.dart';

extension RenderBoxExtension on RenderBox {
  bool containsOffset(Offset global) => size.contains(globalToLocal(global));

  bool containsY(double y) {
    final box = this;
    final widgetPosition = box.localToGlobal(Offset.zero);
    final size = box.size;
    final localY = y - widgetPosition.dy;
    return localY > 0 && size.height >= localY;
  }
}
