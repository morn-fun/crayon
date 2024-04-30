import 'dart:collection';

extension UnmodifiableListViewExtension<T> on UnmodifiableListView<T> {
  UnmodifiableListView<T> addOne(T t) {
    final list = toList();
    list.add(t);
    return UnmodifiableListView(list);
  }

  UnmodifiableListView<T> addMore(Iterable<T> iterable) {
    final list = toList();
    list.addAll(iterable);
    return UnmodifiableListView(list);
  }

  UnmodifiableListView<T> insertOne(int index, T t) {
    final list = toList();
    list.insert(index, t);
    return UnmodifiableListView(list);
  }

  UnmodifiableListView<T> insertMore(int index, Iterable<T> iterable) {
    final list = toList();
    list.insertAll(index, iterable);
    return UnmodifiableListView(list);
  }

  UnmodifiableListView<T> replaceOne(int index, Iterable<T> iterable) {
    final list = toList();
    list.replaceRange(index, index + 1, iterable);
    return UnmodifiableListView(list);
  }

  UnmodifiableListView<T> replaceMore(
      int start, int end, Iterable<T> iterable) {
    final list = toList();
    list.replaceRange(start, end, iterable);
    return UnmodifiableListView(list);
  }
}
