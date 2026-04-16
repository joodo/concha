import 'dart:async';

import 'network.dart';

typedef MusicBrainzLogHandler = void Function(String line);

class MusicBrainzRecording {
  const MusicBrainzRecording({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.lengthMs,
    this.score,
    this.releaseId,
    this.releaseGroupId,
  });

  final String id;
  final String title;
  final String artist;
  final String? album;
  final int? lengthMs;
  final int? score;
  final String? releaseId;
  final String? releaseGroupId;
}

class MusicBrainzService {
  DateTime? _lastRequestAt;

  Future<List<MusicBrainzRecording>> searchRecordings({
    String? title,
    String? artist,
    String? album,
    int limit = 5,
    MusicBrainzLogHandler? onLog,
  }) async {
    final query = _buildQuery(title: title, artist: artist, album: album);
    if (query.isEmpty) {
      return const [];
    }

    await _throttle();

    final uri = Uri.https('musicbrainz.org', '/ws/2/recording', {
      'query': query,
      'fmt': 'json',
      'limit': '$limit',
    });

    onLog?.call('[musicbrainz] GET $uri');
    final response = await http()
        .headers(const {
          'Accept': 'application/json',
          'User-Agent': 'Concha/0.0.1 (music metadata resolver)',
        })
        .getUri(uri);

    final recordings = response.data['recordings'];
    if (recordings is! List) {
      return const [];
    }

    return recordings
        .whereType<Map<String, dynamic>>()
        .map(_parseRecording)
        .whereType<MusicBrainzRecording>()
        .toList();
  }

  Future<void> _throttle() async {
    final lastRequestAt = _lastRequestAt;
    if (lastRequestAt != null) {
      final elapsed = DateTime.now().difference(lastRequestAt);
      const minimumGap = Duration(milliseconds: 1100);
      if (elapsed < minimumGap) {
        await Future<void>.delayed(minimumGap - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();
  }

  String _buildQuery({String? title, String? artist, String? album}) {
    final parts = <String>[];

    final normTitle = _sanitizeTerm(title);
    final normArtist = _sanitizeTerm(artist);
    final normAlbum = _sanitizeTerm(album);

    if (normTitle != null) {
      parts.add('recording:"$normTitle"');
    }
    if (normArtist != null) {
      parts.add('artist:"$normArtist"');
    }
    if (normAlbum != null) {
      parts.add('release:"$normAlbum"');
    }

    if (parts.isNotEmpty) {
      return parts.join(' AND ');
    }

    return [title, artist, album]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(' ');
  }

  String? _sanitizeTerm(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return text.replaceAll('"', ' ');
  }

  MusicBrainzRecording? _parseRecording(Map<String, dynamic> raw) {
    final id = raw['id']?.toString();
    final title = raw['title']?.toString();
    if (id == null || title == null || title.trim().isEmpty) {
      return null;
    }

    final artistCredit = raw['artist-credit'];
    String artist = '未知艺术家';
    if (artistCredit is List && artistCredit.isNotEmpty) {
      final names = artistCredit
          .whereType<Map<String, dynamic>>()
          .map((item) => item['name']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        artist = names.join(', ');
      }
    }

    String? album;
    String? releaseId;
    String? releaseGroupId;
    final releases = raw['releases'];
    if (releases is List && releases.isNotEmpty) {
      final first = releases.first;
      if (first is Map<String, dynamic>) {
        final releaseTitle = first['title']?.toString().trim();
        if (releaseTitle != null && releaseTitle.isNotEmpty) {
          album = releaseTitle;
        }
        final id = first['id']?.toString();
        if (id != null && id.isNotEmpty) {
          releaseId = id;
        }
        final releaseGroup = first['release-group'];
        if (releaseGroup is Map<String, dynamic>) {
          final rgId = releaseGroup['id']?.toString();
          if (rgId != null && rgId.isNotEmpty) {
            releaseGroupId = rgId;
          }
        }
      }
    }

    int? lengthMs;
    final lengthRaw = raw['length'];
    if (lengthRaw is int) {
      lengthMs = lengthRaw;
    } else if (lengthRaw is num) {
      lengthMs = lengthRaw.round();
    }

    int? score;
    final scoreRaw = raw['score'];
    if (scoreRaw is int) {
      score = scoreRaw;
    } else if (scoreRaw is String) {
      score = int.tryParse(scoreRaw);
    }

    return MusicBrainzRecording(
      id: id,
      title: title,
      artist: artist,
      album: album,
      lengthMs: lengthMs,
      score: score,
      releaseId: releaseId,
      releaseGroupId: releaseGroupId,
    );
  }
}
