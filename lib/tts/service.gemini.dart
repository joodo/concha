import 'dart:convert';
import 'dart:typed_data';

import '/utils/http.dart' as app_http;

import 'service.dart';

class GeminiTtsService extends TtsService {
  static const String modelName = 'gemini-2.5-flash-preview-tts';
  static const String voiceName = 'kore';
  static const String? languageCode = null;
  static const Duration requestTimeLimit = Duration(seconds: 30);

  @override
  Future<Uint8List> getVoice(
    String text, {
    required String prompt,
    dynamic apiKey,
    String? proxy,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw ArgumentError.value(text, 'text', '不能为空');
    }

    if (apiKey is! String) {
      throw ArgumentError.value(apiKey, 'geminiKey', '必须为 String');
    }

    final inputText = '$prompt\n\n$normalizedText';

    final client = app_http.Http.createClient(proxy: proxy);

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

      final response = await client
          .post(
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
          )
          .timeout(requestTimeLimit);

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
      return Uint8List.fromList(wavBytes);
    } finally {
      client.close();
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
}
