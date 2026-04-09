extension ScopeFunctionsExtension<T> on T {
  T applyIf<V>(bool condition, T Function(T self) transform) {
    if (condition) {
      return transform(this);
    }
    return this;
  }
}
