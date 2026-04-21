import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/persistence/persistence.dart';
import '/utils/utils.dart';

import 'service.impl.dart';

part 'riverpod.g.dart';

@riverpod
class TextVoice extends _$TextVoice with LoadPersistOrFetch {
  static const _prompt = 'Read aloud slowly and clearly';
  @override
  Future<Uint8List> build(String text) async {
    return loadPersistOrFetch(
      persist: persist(
        ref.watch(persistStorageProvider.future),
        key: 'TextVoice($text)',
        encode: (state) => base64Encode(state),
        decode: (encoded) => base64Decode(encoded),
        options: const StorageOptions(
          cacheTime: StorageCacheTime.unsafe_forever,
        ),
      ),
      fetch: _fetch,
    );
  }

  Future<Uint8List> _fetch() async {
    final client = TtsServiceImpl.fromPref();
    return client.getVoice(text, prompt: _prompt);
  }
}
