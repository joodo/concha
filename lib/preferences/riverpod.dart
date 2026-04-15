import 'dart:ui' as dart;

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:locale_names/locale_names.dart';
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

@riverpod
class Locale extends _$Locale {
  @override
  dart.Locale build() {
    final prefData = Pref._i.getString(_key);
    return prefData.mapOrNull((v) {
          final parts = v.split('-');
          return switch (parts.length) {
            1 => dart.Locale(parts[0]),
            2 => dart.Locale(parts[0], parts[1]),
            _ => dart.Locale(parts[0]),
          };
        }) ??
        PlatformDispatcher.instance.locale;
  }

  void set(dart.Locale newValue) {
    state = newValue;
    Pref._i.setString(_key, newValue.languageCode);
  }

  final String _key = PrefKey.language.name;
}

@riverpod
class TranslateLang extends _$TranslateLang {
  @override
  String build() {
    final currentLanguage = ref.watch(localeProvider).nativeDisplayLanguage;
    final prefData = Pref._i.getString(_key);
    return prefData ?? currentLanguage;
  }

  void set(String newValue) {
    state = newValue;
    Pref._i.setString(_key, newValue);
  }

  final String _key = PrefKey.translateLang.name;
}

@riverpod
class LyricTranslateLangs extends _$LyricTranslateLangs {
  @override
  List<String> build() {
    final translateLang = ref.watch(translateLangProvider);
    final prefData = Pref._i.getStringList(_key);
    return prefData ?? [translateLang];
  }

  void set(List<String> newValue) {
    state = newValue;
    Pref._i.setStringList(_key, newValue);
  }

  final String _key = PrefKey.lyricTranslateLangs.name;
}

extension ToggleExtension on Preference<bool> {
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  void toggle() => set(!(state ?? false));
}

extension WidgetRefPrefExtension on WidgetRef {
  T? getPref<T>(PrefKey key) => read(preferenceProvider<T>(key));
}
