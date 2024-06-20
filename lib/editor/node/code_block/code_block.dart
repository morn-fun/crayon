import 'dart:collection';
import 'package:flutter/material.dart';

import '../../../editor/extension/string.dart';
import '../../core/context.dart';
import '../../cursor/basic.dart';
import '../../cursor/code_block.dart';
import '../../exception/editor_node.dart';
import '../../widget/nodes/code_block.dart';
import '../basic.dart';
import '../rich_text/rich_text.dart';
import 'generator/deletion.dart';
import 'generator/depth.dart';
import 'generator/newline.dart';
import 'generator/paste.dart';
import 'generator/select_all.dart';
import 'generator/typing.dart';

class CodeBlockNode extends EditorNode {
  final String language;
  final UnmodifiableListView<String> codes;

  CodeBlockNode.from(List<String> codes,
      {this.language = 'dart', super.depth, super.id})
      : codes = _buildInitCodes(codes);

  CodeBlockNode from(List<String> codes,
          {String? id, int? depth, String? language}) =>
      CodeBlockNode.from(codes,
          id: id ?? this.id,
          depth: depth ?? this.depth,
          language: language ?? this.language);

  @override
  CodeBlockPosition get beginPosition => CodeBlockPosition.zero(atEdge: true);

  @override
  CodeBlockPosition get endPosition =>
      CodeBlockPosition(codes.length - 1, codes.last.length, atEdge: true);

  static UnmodifiableListView<String> _buildInitCodes(List<String> codes) {
    if (codes.isEmpty) return UnmodifiableListView(['']);
    return UnmodifiableListView(codes);
  }

  @override
  Widget build(NodesOperator operator, NodeBuildParam param, BuildContext c) =>
      CodeBlock(operator, this, param);

  @override
  EditorNode getFromPosition(
      covariant CodeBlockPosition begin, covariant CodeBlockPosition end,
      {String? newId}) {
    if (begin == beginPosition && end == endPosition) {
      return from(codes, id: newId);
    }
    if (begin == end) {
      return RichTextNode.from([], id: newId ?? id, depth: depth);
    }
    CodeBlockPosition left = begin.isLowerThan(end) ? begin : end;
    CodeBlockPosition right = begin.isLowerThan(end) ? end : begin;
    if (left.sameIndex(right)) {
      final code = codes[left.index].substring(left.offset, right.offset);
      return from(UnmodifiableListView([code]), id: newId);
    } else {
      final leftIndex = left.index;
      final rightIndex = right.index;
      var leftCode = codes[leftIndex];
      var rightCode = codes[rightIndex];
      leftCode = leftCode.substring(left.offset, leftCode.length);
      rightCode = rightCode.substring(0, right.offset);
      final newCodes = List.of(codes.getRange(leftIndex, rightIndex + 1));
      newCodes.removeAt(0);
      newCodes.removeLast();
      newCodes.insert(0, leftCode);
      newCodes.add(rightCode);
      return from(UnmodifiableListView(newCodes), id: newId);
    }
  }

  bool isAllSelected(SelectingNodeCursor<CodeBlockPosition> p) =>
      p.left == beginPosition && p.right == endPosition;

  CodeBlockNode replace(
      CodeBlockPosition begin, CodeBlockPosition end, List<String> codes,
      {String? newId}) {
    final left = begin.isLowerThan(end) ? begin : end;
    final right = begin.isLowerThan(end) ? end : begin;

    final copyCodes = List.of(this.codes);
    final leftIndex = left.index;
    final rightIndex = right.index;
    var leftCode = copyCodes[leftIndex];
    var rightCode = copyCodes[rightIndex];
    leftCode = leftCode.substring(0, left.offset);
    rightCode = rightCode.substring(right.offset);

    if (leftIndex == rightIndex) {
      copyCodes.removeAt(leftIndex);
    } else {
      copyCodes.removeRange(leftIndex, rightIndex + 1);
    }
    final newCodes = List.of(codes);
    if (newCodes.isEmpty) {
      newCodes.add(leftCode + rightCode);
    } else {
      newCodes[0] = leftCode + newCodes.first;
      newCodes[newCodes.length - 1] = newCodes.last + rightCode;
    }
    copyCodes.insertAll(leftIndex, newCodes);
    return from(copyCodes, id: newId);
  }

  @override
  CodeBlockNode merge(EditorNode other, {String? newId}) {
    if (other is CodeBlockNode) {
      final oldCodes = List.of(codes);
      final newCodes = List.of(other.codes);
      final mergeCode = oldCodes.removeLast() + newCodes.removeAt(0);
      oldCodes.add(mergeCode);
      oldCodes.addAll(newCodes);
      return from(oldCodes, id: newId);
    } else {
      throw UnableToMergeException('$runtimeType', '${other.runtimeType}');
    }
  }

  @override
  CodeBlockNode newNode({String? id, int? depth}) =>
      from(codes, id: id, depth: depth);

  CodeBlockNode newLanguage(String language) => from(codes, language: language);

  CodeBlockPosition lastPosition(CodeBlockPosition position) {
    final index = position.index;
    final lastIndex = index - 1;
    final offset = position.offset;
    if (offset == 0) {
      try {
        final lastCode = codes[lastIndex];
        final newOffset = lastCode.length;
        return CodeBlockPosition(lastIndex, newOffset);
      } on RangeError {
        throw ArrowLeftBeginException(position);
      }
    } else {
      final code = codes[index];
      try {
        final newOffset = code.lastOffset(offset);
        return CodeBlockPosition(index, newOffset);
      } on RangeError {
        throw ArrowLeftBeginException(position);
      }
    }
  }

  CodeBlockPosition nextPosition(CodeBlockPosition position) {
    final index = position.index;
    final nextIndex = index + 1;
    final offset = position.offset;
    final code = codes[index];
    if (offset == code.length) {
      if (nextIndex >= codes.length) throw ArrowRightEndException(position);
      return CodeBlockPosition(nextIndex, 0);
    }
    try {
      return CodeBlockPosition(index, code.nextOffset(position.offset));
    } on RangeError {
      throw ArrowRightEndException(position);
    }
  }

  @override
  NodeWithCursor onEdit(EditingData data) {
    final type = data.type;
    final generator = _editingGenerator[type.name];
    if (generator == null) {
      throw NodeUnsupportedException(runtimeType, 'onEdit', data);
    }
    return generator.call(data.as<CodeBlockPosition>(), this);
  }

  @override
  NodeWithCursor onSelect(SelectingData data) {
    final type = data.type;
    final generator = _selectingGenerator[type.name];
    if (generator == null) {
      throw NodeUnsupportedException(runtimeType, 'onSelect', data);
    }
    return generator.call(data.as<CodeBlockPosition>(), this);
  }

  @override
  String get text => '''
  ```
  ${codes.join('\n')}
  ```''';

  @override
  Map<String, dynamic> toJson() => {'type': '$runtimeType', 'codes': codes};

  @override
  List<EditorNode> getInlineNodesFromPosition(
          covariant CodeBlockPosition begin, covariant CodeBlockPosition end) =>
      [];
}

final _editingGenerator = <String, _NodeGeneratorWhileEditing>{
  EventType.delete.name: (d, n) => deleteWhileEditing(d, n),
  EventType.newline.name: (d, n) => newlineWhileEditing(d, n),
  EventType.selectAll.name: (d, n) => selectAllWhileEditing(d, n),
  EventType.typing.name: (d, n) => typingWhileEditing(d, n),
  EventType.paste.name: (d, n) => pasteWhileEditing(d, n),
  EventType.increaseDepth.name: (d, n) => increaseDepthWhileEditing(d, n),
  EventType.decreaseDepth.name: (d, n) => decreaseDepthWhileEditing(d, n),
};

final _selectingGenerator = <String, _NodeGeneratorWhileSelecting>{
  EventType.delete.name: (d, n) => deleteWhileSelecting(d, n),
  EventType.newline.name: (d, n) => newlineWhileSelecting(d, n),
  EventType.selectAll.name: (d, n) => selectAllWhileSelecting(d, n),
  EventType.paste.name: (d, n) => pasteWhileSelecting(d, n),
  EventType.increaseDepth.name: (d, n) => increaseDepthWhileSelecting(d, n),
  EventType.decreaseDepth.name: (d, n) => decreaseDepthWhileSelecting(d, n),
};

typedef _NodeGeneratorWhileEditing = NodeWithCursor Function(
    EditingData<CodeBlockPosition> data, CodeBlockNode node);

typedef _NodeGeneratorWhileSelecting = NodeWithCursor Function(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node);
