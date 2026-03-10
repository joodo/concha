import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../utils/http.dart';
import '../utils/shell.dart';

typedef YoutubeDownloadLogHandler = void Function(String line);

class YoutubeDownloadService {
  YoutubeDownloadService({ShellRunner? shellRunner})
    : _shellRunner = shellRunner ?? const ShellRunner();

  final ShellRunner _shellRunner;

  Future<String> downloadAudio({
    required String url,
    String? proxy,
    YoutubeDownloadLogHandler? onLog,
  }) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      throw Exception('YouTube 链接不能为空');
    }

    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null || !uri.hasScheme) {
      throw Exception('无效的 YouTube 链接: $trimmedUrl');
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw Exception('YouTube 链接必须是 http 或 https');
    }

    if (!await _shellRunner.existsInPath('yt-dlp')) {
      throw Exception('未找到 yt-dlp，请先安装并确保其在 PATH 中可用');
    }

    final baseTempDir = await getTemporaryDirectory();
    final tempDir = await Directory(
      baseTempDir.path,
    ).createTemp('concha-youtube-');
    final normalizedProxy = _normalizeProxy(proxy);

    final commandParts = <String>[
      'yt-dlp',
      '-x',
      '--audio-format',
      'mp3',
      '--embed-metadata',
      '--embed-thumbnail',
      '--no-playlist',
      '--paths',
      tempDir.path,
      '--output',
      '%(id)s.%(ext)s',
      if (normalizedProxy != null) ...['--proxy', normalizedProxy],
      trimmedUrl,
    ];

    final command = commandParts.map(ShellRunner.quote).join(' ');
    onLog?.call('[youtube] command: $command');

    final result = await _shellRunner.run(
      command,
      onOutput: (output) => onLog?.call('[yt-${output.tag}] ${output.line}'),
    );

    if (result.exitCode != 0) {
      throw Exception('YouTube 下载失败，退出码 ${result.exitCode}');
    }

    final audioFile = await _findDownloadedAudioFile(tempDir);
    if (audioFile == null) {
      throw Exception('YouTube 下载完成，但未在临时目录找到音频文件');
    }

    onLog?.call('[youtube] downloaded: ${audioFile.path}');
    return audioFile.path;
  }

  String? _normalizeProxy(String? value) {
    final proxyValue = value?.trim() ?? '';
    if (proxyValue.isEmpty) return null;

    try {
      return Http.normalizeProxyUri(proxyValue).toString();
    } catch (_) {
      throw Exception('代理地址格式无效: $proxyValue');
    }
  }

  Future<File?> _findDownloadedAudioFile(Directory dir) async {
    final files = <File>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (_isAudioFile(entity.path)) {
        files.add(entity);
      }
    }

    if (files.isEmpty) {
      return null;
    }

    files.sort((a, b) {
      final aTime = a.statSync().modified;
      final bTime = b.statSync().modified;
      return bTime.compareTo(aTime);
    });

    return files.first;
  }

  bool _isAudioFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.opus') ||
        lower.endsWith('.webm');
  }
}
