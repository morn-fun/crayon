import 'dart:math';

import 'package:crayon/editor/cursor/basic.dart';

import '../../../cursor/code_block.dart';
import '../../../exception/editor_node.dart';
import '../../basic.dart';
import '../code_block.dart';
import '../../../../editor/extension/unmodifiable.dart';

NodeWithCursor increaseDepthWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  final codes = node.codes;
  final code = _tab + codes[p.index];
  return NodeWithCursor(
    node.from(codes.replaceOne(p.index, [code])),
    EditingCursor(
        data.index, CodeBlockPosition(p.index, p.offset + _tab.length)),
  );
}

NodeWithCursor decreaseDepthWhileEditing(
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
  return NodeWithCursor(
    node.from(codes.replaceOne(p.index, [code])),
    EditingCursor(
        data.index, CodeBlockPosition(p.index, p.offset - removeOffset)),
  );
}

NodeWithCursor increaseDepthWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final extras = data.extras;
  final p = data.cursor;
  if (node.isAllSelected(p) && extras is int) {
    if (extras < node.depth) {
      throw DepthNotAbleToIncreaseException(node.runtimeType, node.depth);
    }
    return NodeWithCursor(node.newNode(depth: node.depth + 1), p);
  }
  final codes = node.codes;
  final leftIndex = p.left.index;
  final rightIndex = p.right.index;
  final selectingCodes = codes.getRange(leftIndex, rightIndex + 1);
  final newCodes = <String>[];
  for (var c in selectingCodes) {
    newCodes.add(_tab + c);
  }
  return NodeWithCursor(
      node.from(codes.replaceMore(leftIndex, rightIndex + 1, newCodes)),
      SelectingNodeCursor(
          data.index,
          CodeBlockPosition(leftIndex, p.left.offset + _tab.length),
          CodeBlockPosition(rightIndex, p.right.offset + _tab.length)));
}

NodeWithCursor decreaseDepthWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.cursor;
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
  return NodeWithCursor(
      newNode,
      SelectingNodeCursor(
          data.index,
          CodeBlockPosition(leftIndex,
              min(max(leftOffset - leftDecreaseOffset, 0), leftOffset)),
          CodeBlockPosition(rightIndex,
              min(max(rightOffset - rightDecreaseOffset, 0), rightOffset))));
}

bool startWithTab(String code) => code.startsWith(tabRegexp);

final _tab = '\t' * 4;

RegExp tabRegexp = RegExp(r'^[\t\s]{1,4}');
