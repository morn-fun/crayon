import 'dart:math';

import 'package:crayon/editor/widget/menu/link.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cursor/rich_text.dart';
import '../cursor/node_position.dart';
import '../node/rich_text/rich_text.dart';
import '../node/rich_text/rich_text_span.dart';

extension PainterExtension on TextPainter {
  Offset getOffsetFromTextOffset(int offset, {Rect rect = Rect.zero}) {
    final textPosition = TextPosition(offset: offset);
    return getOffsetForCaret(textPosition, rect);
  }

  List<Widget> buildSelectedAreas(int begin, int end) {
    List<Widget> widgets = [];
    final boxList = getBoxesForSelection(
        TextSelection(baseOffset: begin, extentOffset: end));
    Map<int, double> baseline2MaxHeight = baseline2MaxHeightMap(boxList);
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

  Map<int, double> baseline2MaxHeightMap(List<TextBox> boxList) {
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
    return baseline2MaxHeight;
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
      Map<int, double> baseline2MaxHeight = baseline2MaxHeightMap(boxList);
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
                final baseline = ((box.bottom + box.top) / 2).round();
                final height =
                    baseline2MaxHeight[baseline] ?? (box.bottom - box.top);
                return Positioned(
                    left: box.left,
                    top: baseline - height / 2,
                    child: Container(
                      width: box.right - box.left,
                      height: height,
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
      Map<int, double> baseline2MaxHeight = baseline2MaxHeightMap(boxList);
      int j = 0;
      for (var box in boxList) {
        final baseline = ((box.bottom + box.top) / 2).round();
        final height = baseline2MaxHeight[baseline] ?? (box.bottom - box.top);
        bool isFirst = j == 0;
        bool isLast = j == boxList.length - 1;
        final leftRadius = isFirst ? Radius.circular(4) : Radius.zero;
        final rightRadius = isLast ? Radius.circular(4) : Radius.zero;
        widgets.add(Positioned(
            left: box.left,
            top: baseline - height / 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: leftRadius,
                  bottomLeft: leftRadius,
                  topRight: rightRadius,
                  bottomRight: rightRadius,
                ),
              ),
              child: SizedBox(
                width: box.right - box.left,
                height: height,
              ),
            )));
        j++;
      }
    }
    return widgets;
  }

  TextPosition buildTextPosition(Offset globalPosition, RenderBox? renderBox) {
    final box = renderBox;
    if (box == null) return const TextPosition(offset: 0);
    final widgetPosition = box.localToGlobal(Offset.zero);
    final localPosition =
        globalPosition.translate(-widgetPosition.dx, -widgetPosition.dy);
    return getPositionForOffset(localPosition);
  }
}

typedef OnLinkWidgetEnter = void Function(
    Offset offset, RichTextSpan span, SelectingPosition position);
