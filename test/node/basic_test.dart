import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/test_node_context.dart';

void main() {
  test('EditData-toString', () {
    final d = EditingData(EditingCursor(0, RichTextNodePosition.zero()),
        EventType.typing, TestNodeContext());
    print(d.toString());
  });
}
