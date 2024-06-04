import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/const_texts.dart';

void main() {
  test('EditData-toString', () {
    final painter = TextPainter(
        text: TextSpan(text: constTexts.join('\n')),
        textDirection: TextDirection.ltr);
    painter.layout(maxWidth: 500);
    print(painter.getFullHeightForCaret(TextPosition(offset: 10), Rect.zero));
    print(painter.getFullHeightForCaret(TextPosition(offset: 50), Rect.zero));
    var boxList = painter
        .getBoxesForSelection(TextSelection(baseOffset: 10, extentOffset: 11));
    for (var box in boxList) {
      print(box.toRect());
    }
    boxList = painter
        .getBoxesForSelection(TextSelection(baseOffset: 50, extentOffset: 51));
    for (var box in boxList) {
      print(box.toRect());
    }
  });
}
