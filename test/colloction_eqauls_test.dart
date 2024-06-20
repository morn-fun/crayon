import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:crayon/editor/extension/collection.dart';

void main() {
  test('set equals', () {
    final set1 = <String>{};
    final set2 = <String>{};
    final set3 = <String>{''};
    final uSet1 = UnmodifiableSetView(set1);
    final uSet2 = UnmodifiableSetView(set2);
    final uSet3 = UnmodifiableSetView(set3);
    assert(uSet1.equalsTo(uSet2));
    assert(!uSet1.equalsTo(uSet3));
  });

  test('map equals', () {
    final m1 = <String, String>{};
    final m2 = <String, String>{};
    final m3 = <String, String>{'1': '1'};
    final m4 = <String, String>{'1': '2'};
    final m5 = <String, String>{'1': '2', '3': '4'};
    final m6 = <String, String>{'1': '1', '3': '4'};
    assert(m1.equalsTo(m2));
    assert(!m1.equalsTo(m3));
    assert(!m3.equalsTo(m4));
    assert(!m3.equalsTo(m5));
    assert(!m4.equalsTo(m5));
    assert(!m3.equalsTo(m6));
    assert(!m5.equalsTo(m6));

    assert(m1.immutable().equalsTo(m2.immutable()));
    assert(!m1.immutable().equalsTo(m3.immutable()));
    assert(!m3.immutable().equalsTo(m4.immutable()));
    assert(!m3.immutable().equalsTo(m5.immutable()));
    assert(!m4.immutable().equalsTo(m5.immutable()));
    assert(!m3.immutable().equalsTo(m6.immutable()));
    assert(!m5.immutable().equalsTo(m6.immutable()));
  });

  test('map', () {
    final map = {
      if (true) ...{
        'a': 'a',
        'b': 'b',
        'c': 'c',
      },
    };

    print(map);
  });
}
