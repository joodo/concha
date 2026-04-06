import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/preferences/preferences.dart';
import '/utils/utils.dart';

import 'service.gemini.dart';

part 'riverpod.g.dart';

@Riverpod(keepAlive: true, retry: disableRetry)
Future<Uint8List> textVoice(Ref ref, String text) async {
  final token = ref.getPref<String>(.geminiKey);
  final proxy = ref.getPref<String>(.proxy);
  final prompt = ref.getPref<String>(.speakPrompt);

  final service = GeminiTtsService();
  try {
    return await service.getVoice(
      text,
      prompt: prompt!,
      proxy: proxy,
      apiKey: token,
    );
  } catch (e) {
    Future.microtask(ref.invalidateSelf);
    rethrow;
  }
}
