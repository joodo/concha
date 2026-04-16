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
  String? get nullIfEmpty => isEmpty ? null : this;
}
