import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '/network/network.dart';
import '/utils/utils.dart';

import 'models.dart';

class LrcLibService {
  const LrcLibService._internal();
  static final i = LrcLibService._internal();

  static const _host = 'lrclib.net';

  Future<List<LrcLibLyric>> search(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) {
      return const [];
    }

    final uri = Uri.https(_host, '/api/search', {'q': query});

    final response = await http()
        .headers(const {
          'Accept': 'application/json',
          'User-Agent': 'Concha/0.0.1 (lyrics search)',
        })
        .transform<List<LrcLibLyric>>((json) {
          final list = json as List;
          return list
              .map((e) => LrcLibLyric.fromJson(e))
              .where((lyric) => lyric.syncedLyrics.isNotEmpty)
              .toList(growable: false);
        })
        .getUri<List<LrcLibLyric>>(uri);

    return response.data!;
  }

  Future<void> upload(
    LrcLibLyric lyric, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    onProgress?.call(0.1);

    Response<JsonMap> response = await http().postUri(
      Uri.https(_host, '/api/request-challenge'),
      cancelToken: cancelToken,
    );
    onProgress?.call(0.33);

    final token = await compute(_syncSolve, response.data!);
    onProgress?.call(0.9);

    response = await http()
        .headers(const {
          'Accept': 'application/json',
          'User-Agent': 'Concha/0.0.1 (lyrics upload)',
        })
        .headers({'X-Publish-Token': token})
        .postUri(
          Uri.https(_host, '/api/publish'),
          data: lyric.toJson(),
          cancelToken: cancelToken,
        );
    onProgress?.call(1.0);
  }

  String _syncSolve(JsonMap json) {
    final {'prefix': String prefix, 'target': String targetHex} = json;

    int nonce = 0;
    final target = hex.decode(targetHex);

    while (true) {
      final input = "$prefix$nonce";
      final bytes = utf8.encode(input);
      final hashedBytes = sha256.convert(bytes).bytes;

      bool success = true;
      for (int i = 0; i < hashedBytes.length; i++) {
        if (hashedBytes[i] > target[i]) {
          success = false;
          break;
        } else if (hashedBytes[i] < target[i]) {
          success = true;
          break;
        }
      }

      if (success) {
        return '$prefix:$nonce';
      }

      nonce++;
    }
  }
}
