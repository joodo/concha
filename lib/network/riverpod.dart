import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/persistence/persistence.dart';
import '/utils/utils.dart';

import 'dio.dart';

part 'riverpod.g.dart';

@Riverpod(retry: disableRetry)
class HttpBlob extends _$HttpBlob {
  @override
  Future<Uint8List> build(Uri url) async {
    final link = ref.keepAlive();
    await persist(
      ref.watch(persistStorageProvider.future),
      key: 'HttpBlob(${url.toString()})',
      encode: (state) => base64Encode(state),
      decode: (encoded) => base64Decode(encoded),
      options: const StorageOptions(
        cacheTime: StorageCacheTime(Duration(hours: 6)),
      ),
    ).future;

    if (state.hasValue) {
      link.close();
      return state.requireValue;
    }

    try {
      return await _fetch();
    } finally {
      link.close();
    }
  }

  Future<Uint8List> _fetch() async {
    final response = await http().responseType(.bytes).getUri(url);
    return response.data as Uint8List;
  }
}
