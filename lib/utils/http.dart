import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class Http {
  static Future<http.Response> get(
    String url, {
    Map<String, String>? header,
    String? proxy,
  }) async {
    final uri = Uri.parse(url);
    final client = _createClient(proxy: proxy);

    try {
      return await client.get(uri, headers: header);
    } finally {
      client.close();
    }
  }

  static Future<http.Response> postForm(
    String url, {
    required Map<String, String> form,
    Map<String, String>? header,
    String? proxy,
  }) async {
    final uri = Uri.parse(url);
    final client = _createClient(proxy: proxy);
    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      ...?header,
    };

    try {
      return await client.post(uri, headers: headers, body: form);
    } finally {
      client.close();
    }
  }

  static http.Client _createClient({String? proxy}) {
    final proxyValue = proxy?.trim() ?? '';
    if (proxyValue.isEmpty) {
      return http.Client();
    }

    final proxyUri = normalizeProxyUri(proxyValue);
    final host = proxyUri.host;
    if (host.isEmpty) {
      throw FormatException('Invalid proxy: $proxyValue');
    }

    final port = proxyUri.hasPort ? proxyUri.port : 80;
    final httpClient = HttpClient();
    httpClient.findProxy = (_) => 'PROXY $host:$port';

    final userInfo = proxyUri.userInfo;
    if (userInfo.isNotEmpty) {
      final separator = userInfo.indexOf(':');
      final username = separator == -1
          ? Uri.decodeComponent(userInfo)
          : Uri.decodeComponent(userInfo.substring(0, separator));
      final password = separator == -1
          ? ''
          : Uri.decodeComponent(userInfo.substring(separator + 1));

      httpClient.authenticateProxy =
          (String proxyHost, int proxyPort, String _, String? realm) async {
            httpClient.addProxyCredentials(
              proxyHost,
              proxyPort,
              realm ?? '',
              HttpClientBasicCredentials(username, password),
            );
            return true;
          };
    }

    return IOClient(httpClient);
  }

  static Uri normalizeProxyUri(String proxy) {
    if (proxy.contains('://')) {
      return Uri.parse(proxy);
    }
    return Uri.parse('http://$proxy');
  }
}
