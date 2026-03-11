import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

import 'preferences.dart';

class PreferenceValueNotifier<T> extends ValueNotifier<T> {
  final String key;
  PreferenceValueNotifier(super.value, {required this.key}) {
    final data = Pref.i.get(key);
    if (data.runtimeType == T) {
      value = data as T;
    }

    addListener(
      () => switch (T) {
        const (int) => Pref.i.setInt(key, value as int),
        const (double) => Pref.i.setDouble(key, value as double),
        const (bool) => Pref.i.setBool(key, value as bool),
        const (String) => Pref.i.setString(key, value as String),
        const (List<String>) => Pref.i.setStringList(
          key,
          value as List<String>,
        ),
        Type() => throw TypeError(),
      },
    );
  }
}

class AutoResetNotifier extends ChangeNotifier
    implements ValueListenable<bool> {
  AutoResetNotifier(this.cooldown);

  final Duration cooldown;

  bool __value = false;
  @override
  bool get value => __value;
  set _value(bool newValue) {
    if (__value == newValue) return;
    __value = newValue;
    notifyListeners();
  }

  final _locks = <String>{};
  bool get locked => _locks.isNotEmpty;
  Set<String> get locks => _locks;
  void lockUp(String locker) {
    _value = true;
    _locks.add(locker);
    _resetTimer.cancel();
  }

  void unlock(String locker) {
    if (!_locks.remove(locker)) return;
    if (_locks.isEmpty) _resetTimer.reset();
  }

  void mark() {
    _value = true;
    if (_locks.isEmpty) _resetTimer.reset();
  }

  void reset() {
    if (_locks.isNotEmpty) return;
    _value = false;
    _resetTimer.cancel();
  }

  late final _resetTimer = RestartableTimer(cooldown, () => _value = false)
    ..cancel();

  @override
  void dispose() {
    _resetTimer.cancel();
    super.dispose();
  }
}
