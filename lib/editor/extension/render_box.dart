import 'package:flutter/material.dart' hide TableCell;
import '../cursor/table.dart';

extension RenderBoxExtension on RenderBox {
  bool containsOffset(Offset global) => size.contains(globalToLocal(global));

  bool containsY(double y) {
    final box = this;
    final widgetPosition = box.localToGlobal(Offset.zero);
    final size = box.size;
    final localY = y - widgetPosition.dy;
    return localY > 0 && size.height >= localY;
  }

  bool containsOffsetInTable(Offset global, CellPosition l, CellPosition r,
      List<double> heights, List<double> widths) {
    final topLeft = l.topLeft(r);
    final bottomRight = l.bottomRight(r);
    final absoluteOffset = global - localToGlobal(Offset.zero);
    double lX = 0, lY = 0, rX = 0, rY = 0;
    if (topLeft.column > 0) {
      lX = widths.sublist(0, topLeft.column).reduce((a, b) => a + b);
    }
    rX = widths.sublist(1, bottomRight.column + 2).reduce((a, b) => a + b);
    if (topLeft.row > 0) {
      lY = heights.sublist(0, topLeft.row).reduce(((a, b) => a + b));
    }
    rY = heights.sublist(1, bottomRight.row + 2).reduce((a, b) => a + b);
    final isInCell = absoluteOffset.dx >= lX &&
        absoluteOffset.dx <= rX &&
        absoluteOffset.dy >= lY &&
        absoluteOffset.dy <= rY;
    return isInCell;
  }

  CellPosition? getCellPosition(
      Offset pointerOffset, List<double> heights, List<double> widths) {
    final tableSize = size;
    final tablePosition = localToGlobal(Offset.zero);
    double relativeX = pointerOffset.dx - tablePosition.dx,
        relativeY = pointerOffset.dy - tablePosition.dy;

    if (relativeX < 0 || relativeY < 0) return null;

    int row = -1, column = -1;
    double accumulatedHeight = 0, accumulatedWidth = 0;

    for (int i = 0; i < heights.length; i++) {
      accumulatedHeight += heights[i];
      if (relativeY < accumulatedHeight) {
        row = i;
        break;
      }
    }

    for (int i = 0; i < widths.length; i++) {
      accumulatedWidth += widths[i];
      if (relativeX < accumulatedWidth) {
        column = i;
        break;
      }
    }

    if (row >= tableSize.height ||
        column >= tableSize.width ||
        row < 0 ||
        column < 0) {
      return null;
    }

    return CellPosition(row, column);
  }

  Rect getCellRect(
      CellPosition cellPosition, List<double> heights, List<double> widths) {
    final tablePosition = localToGlobal(Offset.zero);
    double x = tablePosition.dx;
    for (int i = 0; i < cellPosition.column; i++) {
      x += widths[i];
    }

    double y = tablePosition.dy;
    for (int i = 0; i < cellPosition.row; i++) {
      y += heights[i];
    }

    double width = widths[cellPosition.column];
    double height = heights[cellPosition.row];

    return Rect.fromLTWH(x, y, width, height);
  }
}
