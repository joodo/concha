import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../utils/http.dart' as app_http;
import '../utils/preferences.dart';

class GeminiTtsService {
  static const int _maxCacheEntries = 10;
  static final LinkedHashMap<String, Uint8List> _voiceCache =
      LinkedHashMap<String, Uint8List>();

  const GeminiTtsService({
    this.modelName = 'gemini-2.5-flash-preview-tts',
    this.voiceName = 'Kore',
    this.languageCode,
  });

  final String modelName;
  final String voiceName;
  final String? languageCode;

  Future<Uint8List> getVoice(String text) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw ArgumentError.value(text, 'text', '不能为空');
    }

    final cached = _getCachedVoice(normalizedText);
    if (cached != null) {
      return cached;
    }

    final apiKeyValue = Pref.i.get(PrefKeys.geminiKey.value);
    final apiKey = apiKeyValue is String ? apiKeyValue.trim() : '';
    if (apiKey.isEmpty) {
      throw ArgumentError.value(apiKeyValue, 'geminiKey', '不能为空');
    }

    final promptValue = Pref.i.get(PrefKeys.speakPrompt.value);
    final prompt = promptValue is String ? promptValue.trim() : '';
    final inputText = prompt.isEmpty
        ? normalizedText
        : '$prompt\n\n$normalizedText';

    final proxy = Pref.normalizedProxy;
    final http.Client? proxyClient = proxy == null
        ? null
        : app_http.Http.createClient(proxy: proxy);
    final client = proxyClient ?? http.Client();
    final shouldCloseClient = proxyClient == null;

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
      );

      final speechConfig = <String, dynamic>{
        'voiceConfig': {
          'prebuiltVoiceConfig': {'voiceName': voiceName},
        },
      };
      final normalizedLanguageCode = languageCode?.trim() ?? '';
      if (normalizedLanguageCode.isNotEmpty) {
        speechConfig['languageCode'] = normalizedLanguageCode;
      }

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': inputText},
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': speechConfig,
          },
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body.trim();
        final message = body.isEmpty ? 'HTTP ${response.statusCode}' : body;
        throw Exception('语音生成失败：$message');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('语音生成失败：响应格式异常');
      }

      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw Exception('语音生成失败：Gemini 未返回候选内容');
      }

      final firstCandidate = candidates.first;
      if (firstCandidate is! Map<String, dynamic>) {
        throw Exception('语音生成失败：候选内容格式异常');
      }

      final content = firstCandidate['content'];
      if (content is! Map<String, dynamic>) {
        throw Exception('语音生成失败：候选内容缺失');
      }

      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) {
        throw Exception('语音生成失败：未返回音频内容');
      }

      String? audioBase64;
      String? audioMimeType;
      for (final part in parts) {
        if (part is! Map<String, dynamic>) {
          continue;
        }

        final inlineData = part['inlineData'];
        if (inlineData is! Map<String, dynamic>) {
          continue;
        }

        final data = inlineData['data'];
        if (data is String && data.isNotEmpty) {
          audioBase64 = data;
          final mimeType = inlineData['mimeType'];
          if (mimeType is String && mimeType.isNotEmpty) {
            audioMimeType = mimeType;
          }
          break;
        }
      }

      if (audioBase64 == null) {
        throw Exception('语音生成失败：音频数据为空');
      }

      final audioBytes = base64Decode(audioBase64);
      final wavBytes = _toWavBytes(audioBytes, audioMimeType: audioMimeType);
      _cacheVoice(normalizedText, wavBytes);
      return Uint8List.fromList(wavBytes);
    } finally {
      proxyClient?.close();
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Uint8List _toWavBytes(Uint8List audioBytes, {String? audioMimeType}) {
    final normalizedMimeType = audioMimeType?.toLowerCase() ?? '';
    if (normalizedMimeType.contains('wav')) {
      return audioBytes;
    }

    if (normalizedMimeType.isNotEmpty &&
        !normalizedMimeType.contains('pcm') &&
        !normalizedMimeType.contains('l16')) {
      throw Exception('语音生成失败：不支持的音频格式 $audioMimeType');
    }

    return _wrapPcm16ToWav(audioBytes, sampleRate: 24000, channels: 1);
  }

  Uint8List _wrapPcm16ToWav(
    Uint8List pcmBytes, {
    required int sampleRate,
    required int channels,
  }) {
    const bitsPerSample = 16;
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final byteRate = sampleRate * blockAlign;
    final dataLength = pcmBytes.lengthInBytes;
    final fileLength = 44 + dataLength;

    final wavBytes = Uint8List(fileLength);
    final header = ByteData.sublistView(wavBytes, 0, 44);

    _writeAscii(header, 0, 'RIFF');
    header.setUint32(4, 36 + dataLength, Endian.little);
    _writeAscii(header, 8, 'WAVE');
    _writeAscii(header, 12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    _writeAscii(header, 36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    wavBytes.setRange(44, fileLength, pcmBytes);
    return wavBytes;
  }

  void _writeAscii(ByteData data, int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  Uint8List? _getCachedVoice(String text) {
    final cached = _voiceCache.remove(text);
    if (cached == null) {
      return null;
    }

    _voiceCache[text] = cached;
    return Uint8List.fromList(cached);
  }

  void _cacheVoice(String text, Uint8List bytes) {
    _voiceCache.remove(text);
    _voiceCache[text] = Uint8List.fromList(bytes);

    if (_voiceCache.length <= _maxCacheEntries) {
      return;
    }

    _voiceCache.remove(_voiceCache.keys.first);
  }
}
