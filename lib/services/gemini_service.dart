import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/http.dart' as app_http;
import '../utils/preferences.dart';

class GeminiService {
  GeminiService._internal();
  static final i = GeminiService._internal();

  static const modelName = 'gemini-2.5-flash';

  static String get _translatePrompt {
    final targetLang = Pref.i.get(PrefKeys.translatePrompt.value) as String;
    return "你是一个专业的音乐翻译家。请将以下 LRC 歌词翻译成$targetLang。\n"
        "要求：1. 严禁修改或删除 [mm:ss.xx] 格式的时间戳。\n"
        "2. 保持歌词意境优雅。\n"
        "3. 只输出翻译后的 LRC 内容，不要任何解释。\n\n";
  }

  static const _summaryPrompt =
      '你是一个乐评家。请根据以下 LRC 歌词，配一段意象文字。'
      '要求：1. 50 字之内'
      '2. 语气轻松自然'
      '3. 只输出意向文字，不要任何解释';

  Future<String> translate(String lrc) async {
    if (lrc.trim().isEmpty) return '';
    return _request('$_translatePrompt$lrc');
  }

  Future<String> summary(String lrc) async {
    if (lrc.trim().isEmpty) return '';
    return _request('$_summaryPrompt$lrc');
  }

  Future<String> _request(String prompt) async {
    final apiKey = Pref.i.get(PrefKeys.geminiKey.value) as String;
    final normalizedApiKey = apiKey.trim();
    if (normalizedApiKey.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', '不能为空');
    }

    final proxy = Pref.normalizedProxy;
    final http.Client? proxyClient = proxy == null
        ? null
        : app_http.Http.createClient(proxy: proxy);
    final client = proxyClient ?? http.Client();
    final shouldCloseClient = proxyClient == null;

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$normalizedApiKey',
      );

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body.trim();
        final message = body.isEmpty ? 'HTTP ${response.statusCode}' : body;
        throw Exception('歌词翻译失败：$message');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw Exception('歌词翻译失败：Gemini 未返回候选内容');
      }

      final first = candidates.first;
      if (first is! Map<String, dynamic>) {
        throw Exception('歌词翻译失败：Gemini 返回格式异常');
      }

      final content = first['content'];
      if (content is! Map<String, dynamic>) {
        throw Exception('歌词翻译失败：Gemini 返回内容缺失');
      }

      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) {
        throw Exception('歌词翻译失败：Gemini 返回文本为空');
      }

      final responseText = parts
          .whereType<Map<String, dynamic>>()
          .map((part) => part['text'])
          .whereType<String>()
          .join()
          .trim();
      if (responseText.isEmpty) {
        throw Exception('歌词翻译失败：Gemini 未返回有效内容');
      }

      return responseText;
    } finally {
      proxyClient?.close();
      if (shouldCloseClient) {
        client.close();
      }
    }
  }
}
