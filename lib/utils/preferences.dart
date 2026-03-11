import 'package:shared_preferences/shared_preferences.dart';

enum PrefKeys {
  proxy('proxy'),
  acoustKey('acoust_key'),
  autoFillMetadata('auto_fill_metadata'),
  geminiKey('gemini_key'),
  translateLang('translate_lang');

  final String value;
  const PrefKeys(this.value);
}

class Pref {
  static late final SharedPreferencesWithCache i;
  static Future<void> init() async {
    i = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );

    void setIfEmpty(PrefKeys key, String value) {
      if (!i.containsKey(key.value)) i.setString(key.value, value);
    }

    setIfEmpty(.translateLang, '中文');
  }

  static String? get normalizedProxy {
    try {
      final value = i.get(PrefKeys.proxy.value);
      if (value is! String) return null;
      final proxy = value.trim();
      return proxy.isEmpty ? null : proxy;
    } catch (_) {
      return null;
    }
  }
}
