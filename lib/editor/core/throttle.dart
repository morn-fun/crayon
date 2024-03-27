class Throttle {
  static final _tagMap = <String, int>{};

  static void execute(Function callBack,
      {Duration duration = const Duration(milliseconds: 500),
      String tag = 'default'}) {
    final time = _tagMap[tag];
    if (time == null) {
      _tagMap[tag] = DateTime.now().millisecondsSinceEpoch;
      callBack.call();
      return;
    }
    final now = DateTime.now();
    final oldTime = DateTime.fromMillisecondsSinceEpoch(time).add(duration);
    if (now.isAfter(oldTime)) {
      _tagMap[tag] = now.millisecondsSinceEpoch;
      callBack.call();
      return;
    }
  }
}
