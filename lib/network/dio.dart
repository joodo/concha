import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '/preferences/preferences.dart';
import '/utils/utils.dart';

Dio http() {
  final dio = Dio();

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) {
        final proxy = Pref.get<String>(.proxy)?.trim().nullIfEmpty;
        if (proxy != null) {
          return 'PROXY $proxy';
        } else {
          return 'DIRECT';
        }
      };
      return client;
    },
  );

  return dio;
}

extension DioFunctionalExtension on Dio {
  Dio proxy(String? proxy) {
    proxy = proxy?.trim().nullIfEmpty;
    if (proxy == null) return this;

    final adapter = httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      final oldCreateHttpClient = adapter.createHttpClient;
      adapter.createHttpClient = () {
        final client = oldCreateHttpClient?.call() ?? HttpClient();
        client.findProxy = (uri) {
          return 'PROXY $proxy';
        };
        return client;
      };
    }

    return this;
  }

  Dio contentType(String type) => this..options.contentType = type;
  Dio headers(Map<String, String> headers) => this..options.headers = headers;
  Dio responseType(ResponseType type) => this..options.responseType = type;

  Dio acceptAllStatus() => this..options.validateStatus = (_) => true;

  Dio transform<T>(T Function(dynamic json) transformer) =>
      this..transformer = _Transformer(transformer);
}

class _Transformer<T> extends BackgroundTransformer {
  _Transformer(this.transformer);
  final T Function(dynamic json) transformer;

  @override
  Future<T> transformResponse(
    RequestOptions options,
    ResponseBody response,
  ) async {
    final data = await super.transformResponse(options, response) as List;
    return transformer(data);
  }
}
