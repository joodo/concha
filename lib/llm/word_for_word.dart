import '/preferences/preferences.dart';
import '/utils/utils.dart';

import 'service.dart';

String get _systemPrompt {
  final targetLang = Pref.get<String>(.translateLang)!;
  return '''
**Task:** Translate the input sentence into $targetLang and provide a detailed word-by-word or phrase-by-phrase breakdown.
**Requirements:**
1. Provide an accurate and natural translation for the entire `sentence`.
2. In the `detail` array, decompose the sentence into its constituent words or functional phrases.
3. For each item in `detail`, provide its corresponding $targetLang meaning.
''';
}

JsonMap get _jsonFormat {
  final targetLang = Pref.get<String>(.translateLang)!;
  return {
    "name": "translation_response",
    "strict": true,
    "schema": {
      "type": "object",
      "properties": {
        "sentence": {"type": "string"},
        "source_lang": {
          "type": "string",
          "description":
              "MUST provide the detected source language name written in $targetLang characters.",
        },
        "translate": {"type": "string"},
        "detail": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "word": {"type": "string"},
              "translate": {"type": "string"},
              "explanation": {
                "type": "string",
                "description":
                    "Brief usage notes, grammar points, or context in $targetLang(optional, Set to null if no explanation is needed).",
              },
            },
            "required": ["word", "translate", "explanation"],
          },
        },
      },
      "required": ["source_lang", "sentence", "translate", "detail"],
      "additionalProperties": false,
    },
  };
}

Future<JsonMap> createSentenceTranslation(String lyric) {
  final service = LlmService.fromPref();
  return service.generateJson(
    lyric,
    format: _jsonFormat,
    systemPrompt: _systemPrompt,
  );
}
