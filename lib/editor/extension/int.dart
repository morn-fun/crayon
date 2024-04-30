extension IntExtension on int {
  int decrease() {
    return this - 1 >= 0 ? this - 1 : this;
  }
}
