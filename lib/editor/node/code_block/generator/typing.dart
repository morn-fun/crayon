import 'package:flutter/services.dart';

import '../../../../editor/extension/string.dart';
import '../../../../editor/extension/unmodifiable.dart';
import '../../../cursor/basic.dart';
import '../../../cursor/code_block.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../code_block.dart';

NodeWithCursor typingWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final index = p.index;
  final code = node.codes[index];
  final v = data.extras;
  if (v is TextEditingValue) {
    final text = v.text;
    final newCode = code.insert(p.offset, text);
    final newNode = node.from(node.codes.replaceOne(index, [newCode]));
    return NodeWithCursor(
        newNode,
        EditingCursor(
            data.index, CodeBlockPosition(index, p.offset + text.length)));
  }
  throw NodeUnsupportedException(node.runtimeType, 'typingWhileEditing', p);
}