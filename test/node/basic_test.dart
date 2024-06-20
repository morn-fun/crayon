import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/const_texts.dart';
import '../config/necessary.dart';

void main() {
  test('EditData-toString', () {
    final node = RichTextNode.from([]);
    final ctx = buildEditorContext([node]);
    print(EditingData(EditingCursor(100, RichTextNodePosition.zero()),
            EventType.bold, ctx)
        .toString());

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
