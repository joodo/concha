import 'dart:async';

extension ApplyIfExtension<T> on T {
  T applyIf(bool condition, T Function(T self) transform) {
    if (condition) {
      return transform(this);
    }
    return this;
  }
}

extension MapOrNullExtension<T> on T? {
  R? mapOrNull<R>(R? Function(T v) f) => this == null ? null : f(this as T);
}

extension NullIfEmpty on String {
  String? get nullIfEmpty => trim().isEmpty ? null : this;
}

extension AsyncWhereExtension<T> on Stream<T> {
  Stream<T> asyncWhere(FutureOr<bool> Function(T e) test) => asyncMap(
    (event) async => (event, await test(event)),
  ).where((event) => event.$2).map((event) => event.$1);
}

extension MapWhereExtension<K, V> on Map<K, V> {
  Map<K, V> where(bool Function(K key, V value) test) {
    final mapEntries = entries.where((entry) => test(entry.key, entry.value));
    return Map.fromEntries(mapEntries);
  }
}

extension IntersperseIterable<T> on Iterable<T> {
  Iterable<T> intersperse(T element) sync* {
    var first = true;
    for (final item in this) {
      if (!first) yield element;
      yield item;
      first = false;
    }
  }
}
