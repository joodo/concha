import '/llm/llm.dart';

const lyricLineSeparator = '\$\$\$';

String _systemPrompt(List<String> languages) =>
    '''
You are a professional music translator and linguist. Translate the following LRC lyrics into a trilingual format (${languages.join(', ')}).

**Requirements:**
1.  **Strictly forbidden** to modify or delete the `[mm:ss.xx]` formatted timestamps.
2.  Each line must follow this structure: `[mm:ss.xx] ${languages.join(lyricLineSeparator)}`
3.  Maintain an elegant, artistic, and rhythmic flow for all languages.
4.  Output **only** the translated LRC content; do not provide any explanations or introductory text.
''';

Future<String> createLrcTranslation(String lyric, List<String> languages) {
  final service = LlmService.fromPref();
  return service.generate(lyric, systemPrompt: _systemPrompt(languages));
}
