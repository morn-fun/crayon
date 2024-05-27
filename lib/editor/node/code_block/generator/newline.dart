import '../../../../editor/extension/unmodifiable.dart';

import '../../../cursor/basic.dart';
import '../../../cursor/code_block.dart';
import '../../basic.dart';
import '../code_block.dart';

NodeWithCursor newlineWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final codes = node.codes;
  final code = codes[p.index];
  final frontCode = code.substring(0, p.offset);
  final tab = getTab(frontCode);
  final newCodes = [frontCode, tab + code.substring(p.offset, code.length)];
  final newNode = node.from(codes.replaceOne(p.index, newCodes));
  final newPosition = CodeBlockPosition(p.index + 1, tab.length);
  return NodeWithCursor(newNode, EditingCursor(data.index, newPosition));
}

NodeWithCursor newlineWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.cursor;
  final newNode = node.replace(p.left, p.right, []);
  return newlineWhileEditing(
      EditingData(p.leftCursor, EventType.newline, data.operator), newNode);
}

final tabRegex = RegExp(r'^[\t\s]+');

String getTab(String v) {
  final match = tabRegex.firstMatch(v);
  return match?.group(0) ?? '';
}
