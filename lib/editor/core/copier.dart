typedef ValueCopier<T> = T Function(T t);

ValueCopier<T> to<T>(T t) {
  return (v) => t;
}