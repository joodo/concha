import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/utils/utils.dart';

part 'riverpod.g.dart';
part 'service.dart';

@riverpod
class Preference<T> extends _$Preference<T> {
  @override
  T? build(PrefKey key) => Pref.get<T>(key);

  void set(T value) {
    state = value;

    final k = key.toString();
    switch (T) {
      case const (int):
        Pref._i.setInt(k, value as int);
      case const (double):
        Pref._i.setDouble(k, value as double);
      case const (bool):
        Pref._i.setBool(k, value as bool);
      case const (String):
        Pref._i.setString(k, value as String);
      case const (List<String>):
        Pref._i.setStringList(k, value as List<String>);
      default:
        throw TypeError();
    }
  }
}

extension ToggleExtension on Preference<bool> {
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  void toggle() => set(!(state ?? false));
}

extension RefPrefExtension on Ref {
  T? getPref<T>(PrefKey key) => read(preferenceProvider<T>(key));
}

extension WidgetRefPrefExtension on WidgetRef {
  T? getPref<T>(PrefKey key) => read(preferenceProvider<T>(key));
}
