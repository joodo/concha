extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T e) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}
