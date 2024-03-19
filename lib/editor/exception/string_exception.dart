import 'basic_exception.dart';

class OffsetIsEndException implements StringException {
  final String text;
  final int offset;

  OffsetIsEndException(this.text, this.offset);

  String get message => 'offset:$offset is end for [$text]!';

  @override
  String toString() {
    return 'OffsetIsEndException{text: $text, offset: $offset}';
  }
}