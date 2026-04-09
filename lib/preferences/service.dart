part of 'riverpod.dart';

enum PrefKey {
  proxy,

  acoustKey,
  mvsepKey,
  autoFillMetadata(defaultValue: true),

  llmService,
  llmUrl,
  llmKey,
  llmModel,

  ttsService,
  ttsUrl,
  ttsKey,
  ttsModel,

  translateLang(defaultValue: '中文'),
  lyricTranslateLangs,

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
    final k = key.toString();
    late final Object? data;
    switch (T) {
      case const (int):
        data = _i.getInt(k);
      case const (double):
        data = _i.getDouble(k);
      case const (bool):
        data = _i.getBool(k);
      case const (String):
        data = _i.getString(k);
      case const (List<String>):
        data = _i.getStringList(k);
      default:
        data = _i.get(k);
    }
    return data as T?;
  }

  static String? get normalizedProxy {
    try {
      final value = get<String>(.proxy)!;
      final proxy = value.trim();
      return proxy.isEmpty ? null : proxy;
    } catch (_) {
      return null;
    }
  }
}
