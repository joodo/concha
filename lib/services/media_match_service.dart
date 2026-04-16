import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '/preferences/preferences.dart';

import 'acoustid_service.dart';
import 'musicbrainz_service.dart';
import 'network.dart';

typedef MediaMatchLogHandler = void Function(String line);

class MediaMatchCandidate {
  const MediaMatchCandidate({
    required this.title,
    required this.artist,
    required this.source,
    required this.confidence,
    this.album,
    this.recordingId,
    this.releaseId,
    this.releaseGroupId,
  });

  final String title;
  final String artist;
  final String source;
  final String? album;
  final String? recordingId;
  final String? releaseId;
  final String? releaseGroupId;
  final double confidence;

  MediaMatchCandidate copyWith({double? confidence}) {
    return MediaMatchCandidate(
      title: title,
      artist: artist,
      source: source,
      album: album,
      recordingId: recordingId,
      releaseId: releaseId,
      releaseGroupId: releaseGroupId,
      confidence: confidence ?? this.confidence,
    );
  }
}

class MediaMatchResult {
  const MediaMatchResult({
    required this.title,
    required this.artist,
    required this.source,
    required this.confidence,
    required this.candidates,
    this.album,
    this.coverBytes,
  });

  final String title;
  final String artist;
  final String source;
  final String? album;
  final Uint8List? coverBytes;
  final double confidence;
  final List<MediaMatchCandidate> candidates;
}

class MediaMatchService {
  MediaMatchService({
    AcoustIdService? acoustIdService,
    MusicBrainzService? musicBrainzService,
  }) : _acoustIdService = acoustIdService ?? AcoustIdService(),
       _musicBrainzService = musicBrainzService ?? MusicBrainzService();

  final AcoustIdService _acoustIdService;
  final MusicBrainzService _musicBrainzService;

  Future<MediaMatchResult> identifyByAudioPath({
    required String audioPath,
    MediaMatchLogHandler? onLog,
  }) async {
    final localHint = _readLocalHint(audioPath);
    if (localHint.hasAny) {
      onLog?.call(
        '[local] title=${localHint.title ?? '-'} artist=${localHint.artist ?? '-'} album=${localHint.album ?? '-'} cover=${localHint.coverBytes == null ? 'no' : 'yes'}',
      );
    } else {
      onLog?.call('[local] 未读取到可用标签');
    }

    final candidates = <MediaMatchCandidate>[];
    if (localHint.hasAny) {
      candidates.add(
        MediaMatchCandidate(
          title: localHint.title ?? '未知标题',
          artist: localHint.artist ?? '未知艺术家',
          album: localHint.album,
          source: 'local',
          confidence: 0.42,
        ),
      );
    }
    AcoustIdResult? acoustResult;

    try {
      onLog?.call('[pipeline] channel=acoustid start');

      final acoustIdApiKey = Pref.get<String>(PrefKey.acoustKey) ?? '';
      acoustResult = await _acoustIdService.recognizeLocalFile(
        audioFilePath: audioPath,
        apiKey: acoustIdApiKey,
        onLog: onLog,
      );
      onLog?.call(
        '[pipeline] channel=acoustid ok: ${acoustResult.artist} - ${acoustResult.title}',
      );
      final acoustCandidates = _extractAcoustCandidates(acoustResult.raw);
      if (acoustCandidates.isEmpty) {
        candidates.add(
          MediaMatchCandidate(
            title: acoustResult.title,
            artist: acoustResult.artist,
            album: _extractBestAcoustAlbum(acoustResult.raw),
            source: 'acoustid',
            confidence: 0.72,
          ),
        );
      } else {
        candidates.addAll(acoustCandidates);
      }
    } catch (e) {
      onLog?.call('[pipeline] channel=acoustid failed: $e');
    }

    final seeds = _buildMusicBrainzSeeds(localHint, acoustResult);
    for (final seed in seeds.take(2)) {
      try {
        onLog?.call(
          '[pipeline] channel=musicbrainz start: ${seed.title ?? '-'} / ${seed.artist ?? '-'}',
        );
        final searchResults = await _musicBrainzService.searchRecordings(
          title: seed.title,
          artist: seed.artist,
          album: seed.album,
          limit: 6,
          onLog: onLog,
        );

        for (final item in searchResults) {
          final scoreBoost = (item.score ?? 0) / 100.0;
          candidates.add(
            MediaMatchCandidate(
              title: item.title,
              artist: item.artist,
              album: item.album,
              source: 'musicbrainz',
              recordingId: item.id,
              releaseId: item.releaseId,
              releaseGroupId: item.releaseGroupId,
              confidence: (0.50 + scoreBoost * 0.30).clamp(0.0, 1.0),
            ),
          );
        }
        onLog?.call(
          '[pipeline] channel=musicbrainz ok: ${searchResults.length} candidates',
        );
      } catch (e) {
        onLog?.call('[pipeline] channel=musicbrainz failed: $e');
      }
    }

    if (candidates.isEmpty) {
      throw Exception('多渠道识别失败：AcoustID 与 MusicBrainz 均无可用结果');
    }

    final ranked = _rankCandidates(candidates, localHint);
    final best = ranked.first;
    final downloadedCoverBytes = await _downloadCoverFromCaa(
      candidates: ranked,
      onLog: onLog,
    );
    final coverBytes = downloadedCoverBytes ?? localHint.coverBytes;

    onLog?.call('[pipeline] ranking top results:');
    for (final item in ranked.take(3)) {
      onLog?.call(
        '[rank] ${item.source.padRight(10)} conf=${item.confidence.toStringAsFixed(3)} ${item.artist} - ${item.title}',
      );
    }

    return MediaMatchResult(
      title: best.title,
      artist: best.artist,
      album: best.album,
      coverBytes: coverBytes,
      source: best.source,
      confidence: best.confidence,
      candidates: ranked,
    );
  }

  _LocalHint _readLocalHint(String audioPath) {
    try {
      final metadata = readMetadata(File(audioPath), getImage: true);
      final title = _normalizeText((metadata as dynamic).title);
      final artist = _normalizeText((metadata as dynamic).artist);
      final album = _normalizeText((metadata as dynamic).album);
      final coverBytes = (metadata as dynamic).pictures.firstOrNull?.bytes;
      return _LocalHint(
        title: title,
        artist: artist,
        album: album,
        coverBytes: coverBytes,
      );
    } catch (_) {
      return const _LocalHint();
    }
  }

  List<MediaMatchCandidate> _extractAcoustCandidates(Map<String, dynamic> raw) {
    final results = raw['results'];
    if (results is! List) return const [];

    final candidates = <MediaMatchCandidate>[];
    for (final item in results.whereType<Map<String, dynamic>>()) {
      final scoreRaw = item['score'];
      final score = scoreRaw is num ? scoreRaw.toDouble() : 0.0;

      final recordings = item['recordings'];
      if (recordings is! List || recordings.isEmpty) continue;

      for (final recording in recordings.whereType<Map<String, dynamic>>()) {
        final title = _normalizeText(recording['title']);
        if (title == null) continue;
        final artist = _extractArtist(recording) ?? '未知艺术家';

        candidates.add(
          MediaMatchCandidate(
            title: title,
            artist: artist,
            album: _extractAcoustAlbum(recording),
            source: 'acoustid',
            recordingId: recording['id']?.toString(),
            releaseId: _extractReleaseId(recording),
            releaseGroupId: _extractReleaseGroupId(recording),
            confidence: (0.55 + score * 0.40).clamp(0.0, 1.0),
          ),
        );
      }
    }

    return candidates;
  }

  List<_LocalHint> _buildMusicBrainzSeeds(
    _LocalHint localHint,
    AcoustIdResult? acoust,
  ) {
    final seeds = <_LocalHint>[];
    if (localHint.hasAny) {
      seeds.add(localHint);
    }
    if (acoust != null) {
      seeds.add(_LocalHint(title: acoust.title, artist: acoust.artist));
    }

    final unique = <String, _LocalHint>{};
    for (final seed in seeds) {
      final key =
          '${_key(seed.title)}|${_key(seed.artist)}|${_key(seed.album)}';
      unique[key] = seed;
    }

    return unique.values.toList();
  }

  List<MediaMatchCandidate> _rankCandidates(
    List<MediaMatchCandidate> rawCandidates,
    _LocalHint hint,
  ) {
    final merged = <String, MediaMatchCandidate>{};
    for (final c in rawCandidates) {
      final key = '${_key(c.title)}|${_key(c.artist)}|${_key(c.album)}';
      final prev = merged[key];
      final hasBetterScore = prev == null || c.confidence > prev.confidence;
      final hasCoverMbid = _hasCoverMbid(c);
      final prevHasCoverMbid = prev != null && _hasCoverMbid(prev);
      final shouldPreferMbid =
          prev != null &&
          hasCoverMbid &&
          !prevHasCoverMbid &&
          c.confidence >= prev.confidence - 0.02;
      final hasAlbum = c.album?.isNotEmpty ?? false;
      final prevHasAlbum = prev?.album?.isNotEmpty ?? false;
      final shouldPreferAlbum =
          prev != null &&
          hasAlbum &&
          !prevHasAlbum &&
          c.confidence >= prev.confidence - 0.02;

      if (hasBetterScore || shouldPreferMbid || shouldPreferAlbum) {
        merged[key] = c;
      }
    }

    final ranked = merged.values.map((candidate) {
      final titleSim = _similarity(candidate.title, hint.title);
      final artistSim = _similarity(candidate.artist, hint.artist);
      final albumSim = _similarity(candidate.album, hint.album);

      final finalScore =
          (candidate.confidence * 0.65 +
                  titleSim * 0.20 +
                  artistSim * 0.10 +
                  albumSim * 0.05)
              .clamp(0.0, 1.0);

      return candidate.copyWith(confidence: finalScore);
    }).toList()..sort((a, b) => b.confidence.compareTo(a.confidence));

    return ranked;
  }

  Future<Uint8List?> _downloadCoverFromCaa({
    required List<MediaMatchCandidate> candidates,
    MediaMatchLogHandler? onLog,
  }) async {
    for (final candidate in candidates) {
      final urls = <String>[];

      final releaseId = candidate.releaseId;
      if (_isValidMbid(releaseId)) {
        urls.add('https://coverartarchive.org/release/$releaseId/front');
      }

      final releaseGroupId = candidate.releaseGroupId;
      if (_isValidMbid(releaseGroupId)) {
        urls.add(
          'https://coverartarchive.org/release-group/$releaseGroupId/front',
        );
      }

      for (final url in urls) {
        try {
          onLog?.call('[caa] GET $url');
          final response = await http()
              .headers(const {
                'Accept': 'image/*',
                'User-Agent': 'Concha/0.0.1 (cover fetcher)',
              })
              .responseType(.bytes)
              .get(url);
          onLog?.call('[caa] status=${response.statusCode}');
          return response.data;
        } catch (e) {
          onLog?.call('[caa] request failed: $e');
        }
      }
    }

    onLog?.call('[caa] no cover found');
    return null;
  }

  bool _hasCoverMbid(MediaMatchCandidate candidate) {
    return _isValidMbid(candidate.releaseId) ||
        _isValidMbid(candidate.releaseGroupId);
  }

  bool _isValidMbid(String? id) {
    if (id == null) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id.trim());
  }

  String? _extractReleaseId(Map<String, dynamic> recording) {
    final releaseGroups = recording['releasegroups'];
    if (releaseGroups is! List || releaseGroups.isEmpty) {
      return null;
    }

    for (final group in releaseGroups.whereType<Map<String, dynamic>>()) {
      final releases = group['releases'];
      if (releases is! List || releases.isEmpty) continue;
      for (final release in releases.whereType<Map<String, dynamic>>()) {
        final id = release['id']?.toString();
        if (_isValidMbid(id)) {
          return id;
        }
      }
    }

    return null;
  }

  String? _extractBestAcoustAlbum(Map<String, dynamic> raw) {
    final results = raw['results'];
    if (results is! List || results.isEmpty) {
      return null;
    }

    final resultMaps = results.whereType<Map<String, dynamic>>().toList()
      ..sort((a, b) {
        final aScore = (a['score'] is num)
            ? (a['score'] as num).toDouble()
            : 0.0;
        final bScore = (b['score'] is num)
            ? (b['score'] as num).toDouble()
            : 0.0;
        return bScore.compareTo(aScore);
      });

    for (final item in resultMaps) {
      final recordings = item['recordings'];
      if (recordings is! List || recordings.isEmpty) continue;

      for (final recording in recordings.whereType<Map<String, dynamic>>()) {
        final album = _extractAcoustAlbum(recording);
        if (album != null) {
          return album;
        }
      }
    }

    return null;
  }

  String? _extractAcoustAlbum(Map<String, dynamic> recording) {
    final releaseGroups = recording['releasegroups'];
    if (releaseGroups is List && releaseGroups.isNotEmpty) {
      for (final group in releaseGroups.whereType<Map<String, dynamic>>()) {
        final groupTitle = _normalizeText(group['title']);
        if (groupTitle != null) {
          return groupTitle;
        }

        final releases = group['releases'];
        if (releases is! List || releases.isEmpty) continue;
        for (final release in releases.whereType<Map<String, dynamic>>()) {
          final releaseTitle = _normalizeText(release['title']);
          if (releaseTitle != null) {
            return releaseTitle;
          }
        }
      }
    }

    final releases = recording['releases'];
    if (releases is List && releases.isNotEmpty) {
      for (final release in releases.whereType<Map<String, dynamic>>()) {
        final releaseTitle = _normalizeText(release['title']);
        if (releaseTitle != null) {
          return releaseTitle;
        }
      }
    }

    return null;
  }

  String? _extractReleaseGroupId(Map<String, dynamic> recording) {
    final releaseGroups = recording['releasegroups'];
    if (releaseGroups is! List || releaseGroups.isEmpty) {
      return null;
    }

    for (final group in releaseGroups.whereType<Map<String, dynamic>>()) {
      final id = group['id']?.toString();
      if (_isValidMbid(id)) {
        return id;
      }
    }

    return null;
  }

  String? _extractArtist(Map<String, dynamic> recording) {
    final artists = recording['artists'];
    if (artists is! List || artists.isEmpty) return null;

    final first = artists.first;
    if (first is! Map<String, dynamic>) return null;

    return _normalizeText(first['name']);
  }

  double _similarity(String? left, String? right) {
    final l = _key(left);
    final r = _key(right);
    if (l.isEmpty || r.isEmpty) return 0.0;
    if (l == r) return 1.0;
    if (l.contains(r) || r.contains(l)) return 0.8;

    final leftTokens = l.split(' ').where((e) => e.isNotEmpty).toSet();
    final rightTokens = r.split(' ').where((e) => e.isNotEmpty).toSet();
    if (leftTokens.isEmpty || rightTokens.isEmpty) return 0.0;

    final intersection = leftTokens.intersection(rightTokens).length;
    final union = leftTokens.union(rightTokens).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }

  String _key(String? value) {
    final text = (value ?? '').toLowerCase().trim();
    return text.replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), ' ').trim();
  }

  String? _normalizeText(dynamic value) {
    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is String) {
        final text = first.trim();
        return text.isEmpty ? null : text;
      }
    }

    return null;
  }
}

class _LocalHint {
  const _LocalHint({this.title, this.artist, this.album, this.coverBytes});

  final String? title;
  final String? artist;
  final String? album;
  final Uint8List? coverBytes;

  bool get hasAny {
    return (title?.isNotEmpty ?? false) ||
        (artist?.isNotEmpty ?? false) ||
        (album?.isNotEmpty ?? false);
  }
}
