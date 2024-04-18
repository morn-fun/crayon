import 'dart:math';

import 'package:crayon/editor/widget/menu/link_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cursor/rich_text_cursor.dart';
import '../node/position_data.dart';
import '../node/rich_text_node/rich_text_node.dart';
import '../node/rich_text_node/rich_text_span.dart';

extension PainterExtension on TextPainter {
  Offset getOffsetFromTextOffset(int offset, {Rect rect = Rect.zero}) {
    final textPosition = TextPosition(offset: offset);
    return getOffsetForCaret(textPosition, rect);
  }

  List<Widget> buildSelectedAreas(
      SelectingPosition selectingPosition, RichTextNode node) {
    List<Widget> widgets = [];
    final left = selectingPosition.left;
    final right = selectingPosition.right;
    if (left is! RichTextNodePosition || right is! RichTextNodePosition) {
      return widgets;
    }
    final begin = node.getOffset(left);
    final end = node.getOffset(right);
    final boxList = getBoxesForSelection(
        TextSelection(baseOffset: begin, extentOffset: end));
    Map<int, double> baseline2MaxHeight = {};
    for (var box in boxList) {
      final baseline = ((box.bottom + box.top) / 2).round();
      final height = box.bottom - box.top;
      if (baseline2MaxHeight[baseline] == null) {
        baseline2MaxHeight[baseline] = height;
      } else {
        final oldHeight = baseline2MaxHeight[baseline]!;
        baseline2MaxHeight[baseline] = max(oldHeight, height);
      }
    }

    for (var box in boxList) {
      final baseline = ((box.bottom + box.top) / 2).round();
      final height = baseline2MaxHeight[baseline] ?? (box.bottom - box.top);
      widgets.add(Positioned(
          left: box.left,
          top: baseline - height / 2,
          child: Container(
            width: box.right - box.left,
            height: height,
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.5)),
          )));
    }
    return widgets;
  }

  List<Widget> buildLinkGestures(
    RichTextNode node, {
    OnLinkWidgetEnter? onEnter,
    PointerExitEventListener? onExit,
    ValueChanged<RichTextSpan>? onTap,
  }) {
    List<Widget> widgets = [];
    for (var i = 0; i < node.spans.length; ++i) {
      final span = node.spans[i];
      if (!span.tags.contains(RichTextTag.link.name)) continue;
      final boxList = getBoxesForSelection(
          TextSelection(baseOffset: span.offset, extentOffset: span.endOffset));
      final selectingPosition = SelectingPosition(
          RichTextNodePosition(i, 0), RichTextNodePosition(i, span.textLength));
      widgets.add(Theme(
        data: ThemeData(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: LinkHover(
          builder: (hovered) {
            return Stack(
              children: List.generate(boxList.length, (index) {
                final box = boxList[index];
                return Positioned(
                    left: box.left,
                    top: box.top,
                    child: Container(
                      width: box.right - box.left,
                      height: box.bottom - box.top,
                      decoration: hovered
                          ? BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.blueAccent)))
                          : null,
                    ));
              }),
            );
          },
          onEnter: (e) {
            onEnter?.call(e.position, span, selectingPosition);
          },
          onExit: (e) {
            onExit?.call(e);
          },
          onTap: () => onTap?.call(span),
        ),
      ));
    }
    return widgets;
  }

  List<Widget> buildInlineCodes(RichTextNode node) {
    List<Widget> widgets = [];
    for (var i = 0; i < node.spans.length; ++i) {
      final span = node.spans[i];
      if (!span.tags.contains(RichTextTag.code.name)) continue;
      final boxList = getBoxesForSelection(
          TextSelection(baseOffset: span.offset, extentOffset: span.endOffset));
      Map<int, double> baseline2MaxHeight = {};
      for (var box in boxList) {
        final baseline = ((box.bottom + box.top) / 2).round();
        final height = box.bottom - box.top;
        if (baseline2MaxHeight[baseline] == null) {
          baseline2MaxHeight[baseline] = height;
        } else {
          final oldHeight = baseline2MaxHeight[baseline]!;
          baseline2MaxHeight[baseline] = max(oldHeight, height);
        }
      }

      for (var box in boxList) {
        final baseline = ((box.bottom + box.top) / 2).round();
        final height = baseline2MaxHeight[baseline] ?? (box.bottom - box.top);
        widgets.add(Positioned(
            left: box.left,
            top: baseline - height / 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.all(1),
              child: SizedBox(
                width: box.right - box.left,
                height: height,
              ),
            )));
      }
    }
    return widgets;
  }
}

typedef OnLinkWidgetEnter = void Function(
    Offset offset, RichTextSpan span, SelectingPosition position);
