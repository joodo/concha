import 'package:flutter/foundation.dart';

import '/preferences/preferences.dart';

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
