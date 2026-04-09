import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:llm_dart/llm_dart.dart';

import '/preferences/preferences.dart';
import '/utils/utils.dart';

import 'service.dart';
import 'utils.dart';

class TtsServiceImpl implements TtsService {
  static const _googleTtsModel = 'gemini-2.5-flash-preview-tts';

  TtsServiceImpl.fromPref()
    : apiKey = Pref.get(.ttsKey)!,
      service = Pref.get(.ttsService),
      model = Pref.get(.ttsModel),
      url = Pref.get(.ttsUrl),
      proxy = Pref.get(.proxy);

  TtsServiceImpl({
    required this.apiKey,
    required this.service,
    required this.model,
    this.url,
    this.proxy,
  });

  final String apiKey;
  final String service;
  final String model;
  final String? url;
  final String? proxy;

  @override
  Future<void> test() {
    return getVoice('Hello');
  }

  @override
  Future<Uint8List> getVoice(String text, {String? prompt}) async {
    final allPrompt = prompt.mapOrNull((v) => '$v:\n$text') ?? text;

    if (service == 'google') {
      // Ad-hoc case as google provider doesn't have LLMCapability.textToSpeech
      // See https://pub.dev/documentation/llm_dart/latest/builder_llm_builder/LLMBuilder/buildGoogleTTS.html
      return _fetchGoogle(allPrompt);
    }

    if (service == 'openrouter') {
      return _fetchOpenRouter(allPrompt, model);
    }

    final provider = await ai()
        .provider(service)
        .applyIf(url?.isNotEmpty == true, (self) => self.baseUrl(url!))
        .apiKey(apiKey)
        .model(model)
        .applyIf(
          proxy?.isNotEmpty == true,
          (self) => self.http((config) => config.proxy(proxy!)),
        )
        .buildAudio();
    final response = await provider.textToSpeech(
      TTSRequest(text: allPrompt, model: model, format: 'pcm16'),
    );
    return convertToWavBytes(
      response.audioData as Uint8List,
      audioMimeType: response.contentType,
    );
  }

  Future<Uint8List> _fetchGoogle(String allPrompt) async {
    final provider = await ai()
        .google(
          (google) => google
              .ttsModel('gemini-2.5-flash-preview-tts')
              .enableAudioOutput(),
        )
        .apiKey(apiKey)
        .model(_googleTtsModel)
        .applyIf(
          proxy?.isNotEmpty == true,
          (self) => self.http((config) => config.proxy(proxy!)),
        )
        .buildGoogleTTS();

    final response = await provider.generateSpeech(
      GoogleTTSRequest.singleSpeaker(text: allPrompt, voiceName: 'kore'),
    );
    return convertToWavBytes(
      response.audioData as Uint8List,
      audioMimeType: response.contentType,
    );
  }

  Future<Uint8List> _fetchOpenRouter(String allPrompt, String model) async {
    final request = http.Request(
      'POST',
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    });
    request.body = jsonEncode({
      'model': model,
      'modalities': ['text', 'audio'],
      'audio': {'voice': 'alloy', 'format': 'pcm16'},
      'stream': true,
      'messages': [
        {'role': 'user', 'content': allPrompt},
      ],
    });

    final client = Http.createClient(proxy: proxy);
    final response = await client.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = await response.stream.transform(utf8.decoder).join();
      throw Exception('TTS request failed: ${response.statusCode}\n$message');
    }

    final audioBytes = BytesBuilder();
    final buffer = StringBuffer();
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer.write(chunk);

      final lines = buffer.toString().split('\n');
      buffer.clear();

      // Keep unfinished line
      if (!lines.last.endsWith('\n')) {
        buffer.write(lines.removeLast());
      }

      for (final line in lines) {
        if (!line.startsWith('data:')) continue;

        final data = line.substring(5).trim();
        if (data == '[DONE]') break;

        try {
          final json = jsonDecode(data);
          final base64Audio = json['choices']?[0]?['delta']?['audio']?['data'];

          if (base64Audio != null) {
            audioBytes.add(base64Decode(base64Audio));
          }
        } catch (_) {
          // ignore
        }
      }
    }

    final data = audioBytes.toBytes();
    return convertToWavBytes(data);
  }
}
