import 'package:flutter/foundation.dart';

class Logger {
  void i(String message) {
    debugPrint(message);
  }

  void e(String message) {
    debugPrint(message);
  }
}

Logger logger = Logger();
