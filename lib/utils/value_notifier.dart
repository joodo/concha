import 'package:flutter/material.dart';

extension SetterExtension<T> on ValueNotifier<T> {
  void set(T newValue) => value = newValue;
}

extension ClearExtension<T> on ValueNotifier<T?> {
  void clear() => value = null;
}

extension ToggleExtension on ValueNotifier<bool> {
  void toggle() => value = !value;
}
