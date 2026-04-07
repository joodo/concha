extension CamelToSnakeExtension on String {
  String get camelToSnake {
    final exp = RegExp(r'(?<=[a-z0-9])(?=[A-Z])');
    return split(exp).join('_').toLowerCase();
  }
}
