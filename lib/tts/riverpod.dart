import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/persistence/persistence.dart';
import '/preferences/preferences.dart';
import '/utils/utils.dart';

import 'service.gemini.dart';

part 'riverpod.g.dart';

@Riverpod(keepAlive: true, retry: disableRetry)
class TextVoice extends _$TextVoice {
  @override
  Future<Uint8List> build(String text) async {
    await persist(
      ref.watch(storageProvider.future),
      key: 'TextVoice($text)',
      encode: (state) => base64Encode(state),
      decode: (encoded) => base64Decode(encoded),
      options: const StorageOptions(cacheTime: StorageCacheTime.unsafe_forever),
    ).future;
    if (state.value != null) return state.value!;

    return await _fetch();
  }

  Future<Uint8List> _fetch() {
    final token = ref.getPref<String>(.geminiKey);
    final proxy = ref.getPref<String>(.proxy);
    final prompt = ref.getPref<String>(.speakPrompt);
    return GeminiTtsService().getVoice(
      text,
      prompt: prompt!,
      proxy: proxy,
      apiKey: token,
    );
  }
}
