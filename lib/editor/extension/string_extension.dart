import 'package:flutter/material.dart';

extension StringExtension on String {
  String insert(int offset, String text) {
    return substring(0, offset) + text + substring(offset, length);
  }

  String replace(TextRange range, String text) {
    return range.textBefore(this) + text + range.textAfter(this);
  }

  String remove(TextRange range) => replace(range, '');

  String removeLast(){
    final list = characters.toList();
    list.removeLast();
    return list.join();
  }

  StringWithOffset removeAt(int offset){
    final before = substring(0, offset);
    final after = substring(offset, length);
    final list = before.characters.toList();
    list.removeLast();
    final newBefore = list.join();
    return StringWithOffset(newBefore + after, newBefore.length);
  }
}

class StringWithOffset{
  final String text;
  final int offset;

  StringWithOffset(this.text, this.offset);
}
