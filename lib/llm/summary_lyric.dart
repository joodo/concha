import '/preferences/preferences.dart';

import 'service.gemini.dart';

String get _systemPrompt {
  final targetLang = Pref.get<String>(.translateLang)!;
  return '''
You are a music critic. Provide a subtitle for the song based on the following lyrics.
**Requirements:**
1. Keep it under 50 words; language: $targetLang.
2. Maintain a relaxed and natural tone.
3. Output **only** the subtitle; do not provide any explanations.
''';
}

Future<String> createSummary(String lyric) {
  final proxy = Pref.normalizedProxy;
  final apiKey = Pref.get<String>(.geminiKey);

  return GeminiService().generate(
    lyric,
    systemPrompt: _systemPrompt,
    apiKey: apiKey,
    proxy: proxy,
  );
}
