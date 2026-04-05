import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'service.dart';

part 'riverpod.g.dart';

@riverpod
class Preference<T> extends _$Preference<T> {
  @override
  T? build(String key) {
    final data = Pref.i.get(key);
    if (data.runtimeType == T) {
      return data as T;
    }

    return null;
  }

  void set(T value) {
    state = value;

    switch (T) {
      case const (int):
        Pref.i.setInt(key, value as int);
      case const (double):
        Pref.i.setDouble(key, value as double);
      case const (bool):
        Pref.i.setBool(key, value as bool);
      case const (String):
        Pref.i.setString(key, value as String);
      case const (List<String>):
        Pref.i.setStringList(key, value as List<String>);
      default:
        throw TypeError();
    }
  }
}
