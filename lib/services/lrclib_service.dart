import 'dart:convert';

import '../utils/http.dart';

class LrcLibLyric {
  const LrcLibLyric({
    required this.trackName,
    required this.artistName,
    required this.syncedLyrics,
  });

  final String trackName;
  final String artistName;
  final String syncedLyrics;

  factory LrcLibLyric.fromJson(Map<String, dynamic> json) {
    return LrcLibLyric(
      trackName: (json['trackName'] ?? '').toString().trim(),
      artistName: (json['artistName'] ?? '').toString().trim(),
      syncedLyrics: (json['syncedLyrics'] ?? '').toString(),
    );
  }
}

class LrcLibService {
  const LrcLibService();

  Future<List<LrcLibLyric>> search(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) {
      return const [];
    }

    final uri = Uri.https('lrclib.net', '/api/search', {'q': query});
    final response = await Http.get(
      uri.toString(),
      header: const {
        'Accept': 'application/json',
        'User-Agent': 'Concha/0.0.1 (lyrics search)',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('LrcLib 请求失败，HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body);
    if (body is! List) {
      throw Exception('LrcLib 响应格式异常');
    }

    return body
        .map(_asJsonMap)
        .whereType<Map<String, dynamic>>()
        .map(LrcLibLyric.fromJson)
        .where(
          (item) =>
              item.trackName.isNotEmpty ||
              item.artistName.isNotEmpty ||
              item.syncedLyrics.isNotEmpty,
        )
        .toList(growable: false);
  }

  Map<String, dynamic>? _asJsonMap(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
}
