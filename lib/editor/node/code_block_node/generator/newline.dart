import '../../../../editor/extension/unmodifiable_extension.dart';

import '../../../cursor/code_block_cursor.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../code_block_node.dart';

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
  final left = p.left;
  final right = p.right;

  final copyCodes = List.of(node.codes);
  final leftIndex = left.index;
  final rightIndex = right.index;
  var leftCode = copyCodes[leftIndex];
  var rightCode = copyCodes[rightIndex];
  leftCode = leftCode.substring(0, left.offset);
  rightCode = rightCode.substring(right.offset);
  final tab = getTab(leftCode);
  if (leftIndex == rightIndex) {
    copyCodes.removeAt(leftIndex);
  } else {
    copyCodes.removeRange(leftIndex, rightIndex + 1);
  }
  final newCodes = [leftCode, tab + rightCode];
  copyCodes.insertAll(leftIndex, newCodes);
  final newNode = node.from(copyCodes);
  final newPosition = CodeBlockPosition(p.left.index + 1, tab.length);
  return NodeWithPosition(newNode, EditingPosition(newPosition));
}

final tabRegex = RegExp(r'^[\t\s]+');

String getTab(String v) {
  final match = tabRegex.firstMatch(v);
  return match?.group(0) ?? '';
}
