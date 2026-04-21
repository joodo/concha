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
