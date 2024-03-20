import 'package:flutter/material.dart';

extension OffsetExtension on Offset {
  Offset move(Offset other) => translate(other.dx, other.dy);
}
