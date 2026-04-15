import '/utils/utils.dart';

import 'service.dart';

String _systemPrompt(String language) {
  return '''
**Task:** Translate the input sentence into $language and provide a detailed word-by-word or phrase-by-phrase breakdown.
**Requirements:**
1. Provide an accurate and natural translation for the entire `sentence`.
2. In the `detail` array, decompose the sentence into its constituent words or functional phrases.
3. For each item in `detail`, provide its corresponding $language meaning.
''';
}

JsonMap _jsonFormat(String language) {
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
              "MUST provide the detected source language name written in $language characters.",
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
                    "Brief usage notes, grammar points, or context in $language(optional, Set to null if no explanation is needed).",
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

Future<JsonMap> createSentenceTranslation(String lyric, String language) {
  final service = LlmService.fromPref();
  return service.generateJson(
    lyric,
    format: _jsonFormat(language),
    systemPrompt: _systemPrompt(language),
  );
}
