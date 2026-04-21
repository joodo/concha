import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/persistence/persistence.dart';
import '/utils/utils.dart';

import 'dio.dart';

part 'riverpod.g.dart';

@riverpod
class HttpBlob extends _$HttpBlob with LoadPersistOrFetch {
  @override
  Future<Uint8List> build(Uri url) {
    return loadPersistOrFetch(
      persist: persist(
        ref.watch(persistStorageProvider.future),
        key: 'HttpBlob(${url.toString()})',
        encode: (state) => base64Encode(state),
        decode: (encoded) => base64Decode(encoded),
        options: const StorageOptions(
          cacheTime: StorageCacheTime(Duration(hours: 6)),
        ),
      ),
      fetch: _fetch,
    );
  }

  Future<Uint8List> _fetch() async {
    final response = await http().responseType(.bytes).getUri(url);
    return response.data as Uint8List;
  }
}
