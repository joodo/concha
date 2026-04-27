import 'dart:async';

import 'package:flutter/foundation.dart';

extension SetterExtension<T> on ValueNotifier<T> {
  void set(T newValue) => value = newValue;
}

extension ClearExtension<T> on ValueNotifier<T?> {
  void clear() => value = null;
}

extension ToggleExtension on ValueNotifier<bool> {
  void toggle() => value = !value;
}

class AutoResetNotifier extends ChangeNotifier
    implements ValueListenable<bool> {
  AutoResetNotifier([this.duration = const Duration(seconds: 3)]);
  final Duration duration;

  Timer? _timer;

  void mark() {
    _value = true;
    _timer = Timer(duration, reset);
    notifyListeners();
  }

  void reset() {
    _value = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _value = false;
  @override
  bool get value => _value;
}
