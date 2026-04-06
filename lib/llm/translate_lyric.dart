import '/preferences/preferences.dart';

import 'service.gemini.dart';

String get _systemPrompt {
  final targetLang = Pref.get<String>(.translateLang)!;
  return '''
You are a professional music translator. Translate the following LRC lyrics into $targetLang.
**Requirements:**
1. **Strictly forbidden** to modify or delete the [mm:ss.xx] formatted timestamps.
2. Maintain an elegant and artistic mood for the lyrics.
3. Output **only** the translated LRC content; do not provide any explanations.
''';
}

Future<String> createTranslatedLyric(String lrc) {
  final proxy = Pref.normalizedProxy;
  final apiKey = Pref.get<String>(.geminiKey);

  return GeminiService().generate(
    lrc,
    systemPrompt: _systemPrompt,
    apiKey: apiKey,
    proxy: proxy,
  );
}
