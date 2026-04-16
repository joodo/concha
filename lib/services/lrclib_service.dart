import '/services/services.dart';

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
  const LrcLibService._internal();
  static final i = LrcLibService._internal();

  Future<List<LrcLibLyric>> search(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) {
      return const [];
    }

    final uri = Uri.https('lrclib.net', '/api/search', {'q': query});

    final response = await http()
        .headers(const {
          'Accept': 'application/json',
          'User-Agent': 'Concha/0.0.1 (lyrics search)',
        })
        .transform<List<LrcLibLyric>>((json) {
          final list = json as List;
          return list
              .map((e) => LrcLibLyric.fromJson(e))
              .where(
                (item) =>
                    item.trackName.isNotEmpty ||
                    item.artistName.isNotEmpty ||
                    item.syncedLyrics.isNotEmpty,
              )
              .toList(growable: false);
        })
        .get<List<LrcLibLyric>>(uri.toString());

    return response.data!;
  }
}
