import '/preferences/preferences.dart';

import 'service.dart';

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
  final service = LlmService.fromPref();
  return service.generate(lyric, systemPrompt: _systemPrompt);
}
