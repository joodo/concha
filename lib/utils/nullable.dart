extension ObjectExt<T> on T? {
  R? mapOrNull<R>(R? Function(T v) f) => this == null ? null : f(this as T);
}
