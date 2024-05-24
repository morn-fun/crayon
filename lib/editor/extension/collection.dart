import 'dart:collection';
import 'dart:math';

extension SetExtension<E> on Set<E> {
  Set<E> addOne(E e) {
    final newSet = Set.of(this);
    newSet.add(e);
    return newSet;
  }

  Set<E> removeOne(E e) {
    final newSet = Set.of(this);
    newSet.remove(e);
    return newSet;
  }

  bool equalsTo(Set<E> other) {
    if (length != other.length) return false;
    for (var o in other) {
      if (!contains(o)) {
        return false;
      }
    }
    return true;
  }

  UnmodifiableSetView<E> immutable() => UnmodifiableSetView(this);
}

extension MapExtension<K, V> on Map<K, V> {
  bool equalsTo(Map<K, V> other) {
    if (length != other.length) return false;
    for (var e in other.entries) {
      final v = this[e.key];
      if (v != e.value) {
        return false;
      }
    }
    return true;
  }

  UnmodifiableMapView<K, V> immutable() => UnmodifiableMapView(this);
}

extension ListExtension<T extends num> on List<T> {
  List<T> mergeLists(List<T> list) {
    List<T> mergedList = [];
    int maxLength = max(length, list.length);
    for (int i = 0; i < maxLength; i++) {
      T maxV;
      if (i < length && i < list.length) {
        maxV = max(this[i], list[i]);
      } else if (i < length) {
        maxV = this[i];
      } else {
        maxV = list[i];
      }
      mergedList.add(maxV);
    }
    return mergedList;
  }
}
