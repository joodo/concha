import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/persistence/persistence.dart';
import '/preferences/preferences.dart';
import '/utils/utils.dart';

import 'service.gemini.dart';

part 'riverpod.g.dart';

@Riverpod(retry: disableRetry)
class TextVoice extends _$TextVoice {
  static const _prompt = 'Read aloud slowly and clearly';
  @override
  Future<Uint8List> build(String text) async {
    final link = ref.keepAlive();
    await persist(
      ref.watch(storageProvider.future),
      key: 'TextVoice($text)',
      encode: (state) => base64Encode(state),
      decode: (encoded) => base64Decode(encoded),
      options: const StorageOptions(cacheTime: StorageCacheTime.unsafe_forever),
    ).future;

    if (state.hasValue) {
      link.close();
      return state.requireValue;
    }

    final result = await _fetch();

    link.close();
    return result;
  }

  Future<Uint8List> _fetch() {
    final token = ref.getPref<String>(.geminiKey);
    final proxy = ref.getPref<String>(.proxy);
    return GeminiTtsService().getVoice(
      text,
      prompt: _prompt,
      proxy: proxy,
      apiKey: token,
    );
  }
}
