import 'package:flutter/material.dart';

class RichTextPainter extends CustomPainter {
  final TextPainter _painter;

  RichTextPainter(this._painter);

  @override
  void paint(Canvas canvas, Size size) {
    Rect background = Rect.fromLTWH(0, 0, size.width, size.height);
    if(size == Size.zero){
      background = Rect.fromLTWH(0, 0, _painter.width, _painter.height);
    }
    Paint backgroundPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(background, backgroundPaint);
    _painter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}