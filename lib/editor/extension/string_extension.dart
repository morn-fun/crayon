import 'dart:ui';

extension StringExtension on String {
  String insert(int offset, String text) {
    return substring(0, offset) + text + substring(offset, length);
  }

  String replace(TextRange range, String text) {
    return range.textBefore(this) + text + range.textAfter(this);
  }

  String remove(TextRange range) => replace(range, '');
}
