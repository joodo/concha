import 'dart:convert';

import '/utils/utils.dart';

import 'service.dart';

class GeminiService extends LlmService {
  static const modelName = 'gemini-2.5-flash';

  @override
  Future<String> generate(
    String prompt, {
    apiKey,
    String? systemPrompt,
    String? proxy,
  }) {
    return _generate(
      prompt,
      apiKey: apiKey,
      systemPrompt: systemPrompt,
      proxy: proxy,
    );
  }

  @override
  Future<JsonMap> generateJson(
    String prompt, {
    required JsonMap format,
    apiKey,
    String? systemPrompt,
    String? proxy,
  }) async {
    final r = await _generate(
      prompt,
      systemPrompt: systemPrompt,
      useJsonFormat: format,
      apiKey: apiKey,
      proxy: proxy,
    );
    return jsonDecode(r);
  }

  Future<String> _generate(
    String prompt, {
    apiKey,
    String? systemPrompt,
    String? proxy,
    Map<String, dynamic>? useJsonFormat,
  }) async {
    if (apiKey is! String) {
      throw ArgumentError.value(apiKey, 'apiKey', 'must be String');
    }

    final client = Http.createClient(proxy: proxy);

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
      );

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (systemPrompt != null)
            'systemInstruction': {
              'parts': [
                {'text': systemPrompt},
              ],
            },
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          if (useJsonFormat != null)
            "generationConfig": {
              "response_mime_type": "application/json",
              "response_schema": useJsonFormat,
            },
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body.trim();
        final message = body.isEmpty ? 'HTTP ${response.statusCode}' : body;
        throw Exception('Gemini failed: $message');
      }

      final decoded = jsonDecode(response.body);
      final parts = decoded['candidates'].first['content']['parts'] as List;
      final responseText = parts
          .map((part) => part['text'] as String)
          .join()
          .trim();
      return responseText;
    } finally {
      client.close();
    }
  }
}
