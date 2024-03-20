import 'package:flutter/material.dart';

extension PainterExtension on TextPainter {
  Offset getOffsetFromTextOffset(int offset, {Rect rect = Rect.zero}) {
    final textPosition = TextPosition(offset: offset);
    return getOffsetForCaret(textPosition, rect);
  }

  OffsetWithLineHeight getOffsetWithLineHeight(
      TextPosition textPosition, Rect rect,
      {double lineHeight = 16}) {
    final off = getOffsetForCaret(textPosition, rect);
    final lh = getFullHeightForCaret(textPosition, Rect.zero) ?? lineHeight;
    return OffsetWithLineHeight(off, lh);
  }
}

class OffsetWithLineHeight {
  final Offset offset;
  final double lineHeight;

  OffsetWithLineHeight(this.offset, this.lineHeight);

  @override
  String toString() {
    return '{offset: $offset, lineHeight: $lineHeight}';
  }
}
