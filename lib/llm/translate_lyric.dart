import '/lyric_controller/lyric_controller.dart';
import '/preferences/preferences.dart';

import 'service.dart';

String get _systemPrompt {
  final targetLangs =
      Pref.get<List<String>>(.lyricTranslateLangs) ??
      [Pref.get<String>(.translateLang)!];

  return '''
You are a professional music translator and linguist. Translate the following LRC lyrics into a trilingual format (${targetLangs.join(', ')}).

**Requirements:**
1.  **Strictly forbidden** to modify or delete the `[mm:ss.xx]` formatted timestamps.
2.  Each line must follow this structure: `[mm:ss.xx] ${targetLangs.join(MultiLineLyricExtension.lineSeparator)}`
3.  Maintain an elegant, artistic, and rhythmic flow for all languages.
4.  Output **only** the translated LRC content; do not provide any explanations or introductory text.
''';
}

Future<String> createLrcTranslation(String lyric) {
  final service = LlmService.fromPref();
  return service.generate(lyric, systemPrompt: _systemPrompt);
}
