import 'package:crayon/editor/cursor/code_block.dart';
import 'package:crayon/editor/node/code_block/code_block_node.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/const_texts.dart';

void main() {
  CodeBlockNode basicNode({List<String>? texts}) =>
      CodeBlockNode.from(texts ?? constTexts);

  test('edge position', () {
    final node = basicNode();
    assert(node.beginPosition.offset == 0);
    assert(node.beginPosition.index == 0);
    assert(node.beginPosition.inEdge == true);
    assert(node.endPosition.offset == constTexts.last.length);
    assert(node.endPosition.index == constTexts.length - 1);
    assert(node.endPosition.inEdge == true);
  });

  test('getFromPosition', () {
    var node = basicNode();
    var n1 = node.frontPartNode(CodeBlockPosition(5, 0));
    assert(n1 is CodeBlockNode);
    final sublist = constTexts.sublist(0, 5).join();
    final text = n1.text.replaceAll('\n', '');
    assert(text == sublist);
  });
}
