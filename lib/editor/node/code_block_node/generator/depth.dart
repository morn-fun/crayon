import 'dart:math';

import '../../../cursor/code_block_cursor.dart';
import '../../../exception/editor_node_exception.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../code_block_node.dart';
import '../../../../editor/extension/unmodifiable_extension.dart';

NodeWithPosition increaseDepthWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final codes = node.codes;
  final code = _tab + codes[p.index];
  return NodeWithPosition(
    node.from(codes.replaceOne(p.index, [code])),
    EditingPosition(CodeBlockPosition(p.index, p.offset + _tab.length)),
  );
}

NodeWithPosition decreaseDepthWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final codes = node.codes;
  var code = codes[p.index];
  int removeOffset = 0;

  if (startWithTab(code)) {
    final newCode = code.replaceFirst(tabRegexp, '');
    removeOffset = code.length - newCode.length;
    code = newCode;
  }
  return NodeWithPosition(
    node.from(codes.replaceOne(p.index, [code])),
    EditingPosition(CodeBlockPosition(p.index, p.offset - removeOffset)),
  );
}

NodeWithPosition increaseDepthWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final extras = data.extras;
  final p = data.position;
  if (node.isAllSelected(p) && extras is int) {
    if (extras < node.depth) {
      throw DepthNotAbleToIncreaseException(node.runtimeType, node.depth);
    }
    return NodeWithPosition(node.newNode(depth: node.depth + 1), p);
  }
  final codes = node.codes;
  final leftIndex = p.left.index;
  final rightIndex = p.right.index;
  final selectingCodes = codes.getRange(leftIndex, rightIndex + 1);
  final newCodes = <String>[];
  for (var c in selectingCodes) {
    newCodes.add(_tab + c);
  }
  return NodeWithPosition(
      node.from(codes.replaceMore(leftIndex, rightIndex + 1, newCodes)),
      SelectingPosition(
          CodeBlockPosition(leftIndex, p.left.offset + _tab.length),
          CodeBlockPosition(rightIndex, p.right.offset + _tab.length)));
}

NodeWithPosition decreaseDepthWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  if (node.isAllSelected(p)) {
    throw DepthNeedDecreaseMoreException(node.runtimeType, node.depth);
  }
  final codes = node.codes;
  final leftIndex = p.left.index;
  final rightIndex = p.right.index;
  final selectingCodes = codes.getRange(leftIndex, rightIndex + 1);
  final newCodes = <String>[];
  for (var code in selectingCodes) {
    if (startWithTab(code)) {
      code = code.replaceFirst(tabRegexp, '');
    }
    newCodes.add(code);
  }
  int leftDecreaseOffset = codes[leftIndex].length - newCodes.first.length;
  int rightDecreaseOffset = codes[rightIndex].length - newCodes.last.length;
  final leftOffset = p.left.offset;
  final rightOffset = p.right.offset;
  final newNode =
      node.from(codes.replaceMore(leftIndex, rightIndex + 1, newCodes));
  return NodeWithPosition(
      newNode,
      SelectingPosition(
          CodeBlockPosition(leftIndex,
              min(max(leftOffset - leftDecreaseOffset, 0), leftOffset)),
          CodeBlockPosition(rightIndex,
              min(max(rightOffset - rightDecreaseOffset, 0), rightOffset))));
}

bool startWithTab(String code) => code.startsWith(tabRegexp);

final _tab = '\t' * 4;

RegExp tabRegexp = RegExp(r'^[\t\s]{1,4}');
