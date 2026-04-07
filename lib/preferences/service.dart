part of 'riverpod.dart';

enum PrefKey {
  proxy(),
  acoustKey(),
  autoFillMetadata(defaultValue: true),
  geminiKey(),
  translateLang(defaultValue: '中文'),
  mvsepKey(),
  playLoop(defaultValue: false),
  attachToLyric(defaultValue: true);

  final Object? defaultValue;
  const PrefKey({this.defaultValue});

  @override
  String toString() => name.camelToSnake;
}

class Pref {
  static late final SharedPreferencesWithCache _i;
  static Future<void> init() async {
    _i = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  }

  static T? get<T>(PrefKey key) {
    final data = _i.get(key.toString()) as T?;
    return data ?? (key.defaultValue as T?);
  }

  static String? get normalizedProxy {
    try {
      final value = get(PrefKey.proxy);
      if (value is! String) return null;
      final proxy = value.trim();
      return proxy.isEmpty ? null : proxy;
    } catch (_) {
      return null;
    }
  }
}
