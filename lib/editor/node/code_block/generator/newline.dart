import '../../../../editor/extension/unmodifiable.dart';

import '../../../cursor/code_block.dart';
import '../../basic.dart';
import '../../../cursor/node_position.dart';
import '../code_block.dart';

NodeWithPosition newlineWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final codes = node.codes;
  final code = codes[p.index];
  final tab = getTab(code);
  final newCodes = [
    code.substring(0, p.offset),
    tab + code.substring(p.offset, code.length)
  ];
  final newNode = node.from(codes.replaceOne(p.index, newCodes));
  final newPosition = CodeBlockPosition(p.index + 1, tab.length);
  return NodeWithPosition(newNode, EditingPosition(newPosition));
}

NodeWithPosition newlineWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final newNode = node.replace(p.left, p.right, []);
  return newlineWhileEditing(EditingData(p.left, EventType.newline, data.context), newNode);
}

final tabRegex = RegExp(r'^[\t\s]+');

String getTab(String v) {
  final match = tabRegex.firstMatch(v);
  return match?.group(0) ?? '';
}
