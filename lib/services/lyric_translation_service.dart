import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

import '../utils/http.dart' as app_http;
import '../utils/preferences.dart';

class LyricTranslationService {
  const LyricTranslationService({this.modelName = 'gemini-3-flash-preview'});

  final String modelName;

  static const String _prompt =
      "你是一个专业的音乐翻译家。请将以下 LRC 歌词翻译成中文。\n"
      "要求：1. 严禁修改或删除 [mm:ss.xx] 格式的时间戳。\n"
      "2. 保持歌词意境优雅。\n"
      "3. 只输出翻译后的 LRC 内容，不要任何解释。\n\n";

  Future<String> translate(String lrc, {required String apiKey}) async {
    final normalizedApiKey = apiKey.trim();
    if (normalizedApiKey.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', '不能为空');
    }

    if (lrc.trim().isEmpty) {
      return '';
    }

    final proxy = _readProxyFromPreferences();
    final http.Client? proxyClient = proxy == null
        ? null
        : app_http.Http.createClient(proxy: proxy);

    try {
      final generativeModel = GenerativeModel(
        model: modelName,
        apiKey: normalizedApiKey,
        httpClient: proxyClient,
      );

      final response = await generativeModel.generateContent([
        Content.text('$_prompt$lrc'),
      ]);

      final translatedLrc = response.text?.trim();
      if (translatedLrc == null || translatedLrc.isEmpty) {
        throw Exception('歌词翻译失败：Gemini 未返回有效内容');
      }

      return translatedLrc;
    } finally {
      proxyClient?.close();
    }
  }

  String? _readProxyFromPreferences() {
    try {
      final value = Pref.i.get('proxy');
      if (value is! String) return null;
      final proxy = value.trim();
      return proxy.isEmpty ? null : proxy;
    } catch (_) {
      return null;
    }
  }
}
