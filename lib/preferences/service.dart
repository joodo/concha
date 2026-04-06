import 'package:shared_preferences/shared_preferences.dart';

enum PrefKeys {
  proxy('proxy'),
  acoustKey('acoust_key'),
  autoFillMetadata('auto_fill_metadata'),
  geminiKey('gemini_key'),
  translateLang('translate_prompt'),
  speakPrompt('read_aloud_prompt'),
  mvsepKey('mvsep_key'),
  playLoop('play_loop'),
  attachToLyric('attach_to_lyric');

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
    setIfEmpty(.speakPrompt, '缓慢而清晰地大声读出');
  }

  static T? get<T>(PrefKeys key) => i.get(key.value) as T?;

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
