import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '/preferences/preferences.dart';

import '../utils/utils.dart';

typedef YoutubeDownloadLogHandler = void Function(String line);

class YoutubeDownloadService {
  YoutubeDownloadService({ShellRunner? shellRunner})
    : _shellRunner = shellRunner ?? const ShellRunner();

  final ShellRunner _shellRunner;

  Future<String> downloadAudio({
    required String url,
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

    final proxy = Pref.normalizedProxy;
    final ytDlpExecutable = await _ensureYtDlp(proxy: proxy, onLog: onLog);

    final baseTempDir = await getTemporaryDirectory();
    final tempDir = await Directory(
      baseTempDir.path,
    ).createTemp('concha-youtube-');

    final commandParts = <String>[
      ytDlpExecutable,
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
      if (proxy != null) ...['--proxy', proxy],
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

  Future<String> _ensureYtDlp({
    String? proxy,
    YoutubeDownloadLogHandler? onLog,
  }) async {
    final localYtDlpPath = await _appBinYtDlpPath();
    if (await File(localYtDlpPath).exists()) {
      await _ensureExecutablePermission(localYtDlpPath, onLog: onLog);
      onLog?.call('[tool] 使用本地 yt-dlp: $localYtDlpPath');
      return localYtDlpPath;
    }

    if (await _shellRunner.existsInPath('yt-dlp')) {
      onLog?.call('[tool] 使用系统 yt-dlp');
      return 'yt-dlp';
    }

    onLog?.call('[tool] 未在 PATH 中找到 yt-dlp，尝试自动下载');
    return _downloadPrebuiltYtDlp(proxy: proxy, onLog: onLog);
  }

  Future<String> _downloadPrebuiltYtDlp({
    String? proxy,
    YoutubeDownloadLogHandler? onLog,
  }) async {
    final targetPath = await _appBinYtDlpPath();
    final binDir = Directory(await _appBinDirPath());
    if (!await binDir.exists()) {
      await binDir.create(recursive: true);
    }

    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await _ensureExecutablePermission(targetPath, onLog: onLog);
      onLog?.call('[tool] 使用 appSupportDir/bin 中已下载的 yt-dlp: $targetPath');
      return targetPath;
    }

    for (final url in _candidateYtDlpUrls()) {
      onLog?.call('[download] $url');
      final response = await Http.get(url, proxy: proxy);
      if (response.statusCode != 200) {
        onLog?.call('[download] HTTP ${response.statusCode}, skip');
        continue;
      }

      if (response.bodyBytes.isEmpty) {
        onLog?.call('[download] 文件为空, skip');
        continue;
      }

      await targetFile.writeAsBytes(response.bodyBytes, flush: true);
      await _ensureExecutablePermission(targetPath, onLog: onLog);
      onLog?.call('[tool] 已下载 yt-dlp 到 appSupportDir/bin: $targetPath');
      return targetPath;
    }

    throw Exception('自动下载 yt-dlp 失败，请检查网络/代理，或手动安装 yt-dlp');
  }

  List<String> _candidateYtDlpUrls() {
    const latestBase =
        'https://github.com/yt-dlp/yt-dlp/releases/latest/download';
    final arch = _detectArch();

    if (Platform.isWindows) {
      return const ['$latestBase/yt-dlp.exe'];
    }

    if (Platform.isMacOS) {
      return const [
        '$latestBase/yt-dlp_macos',
        '$latestBase/yt-dlp_macos_legacy',
        '$latestBase/yt-dlp',
      ];
    }

    if (Platform.isLinux) {
      if (arch == 'arm64') {
        return const ['$latestBase/yt-dlp_linux_aarch64', '$latestBase/yt-dlp'];
      }
      if (arch == 'armv7') {
        return const ['$latestBase/yt-dlp_linux_armv7l', '$latestBase/yt-dlp'];
      }
      return const ['$latestBase/yt-dlp_linux', '$latestBase/yt-dlp'];
    }

    return const ['$latestBase/yt-dlp'];
  }

  String _detectArch() {
    final text = '${Platform.version} ${Platform.operatingSystemVersion}'
        .toLowerCase();

    if (text.contains('aarch64') || text.contains('arm64')) {
      return 'arm64';
    }
    if (text.contains('armv7')) {
      return 'armv7';
    }
    if (text.contains('x86_64') || text.contains('amd64')) {
      return 'x64';
    }

    return 'unknown';
  }

  Future<void> _ensureExecutablePermission(
    String path, {
    YoutubeDownloadLogHandler? onLog,
  }) async {
    if (Platform.isWindows) {
      return;
    }

    final chmodResult = await _shellRunner.run(
      'chmod +x ${ShellRunner.quote(path)}',
    );
    if (chmodResult.exitCode != 0) {
      throw Exception('设置 yt-dlp 可执行权限失败');
    }
    onLog?.call('[tool] chmod +x $path');
  }

  Future<String> _appBinDirPath() async {
    final appDir = await getApplicationSupportDirectory();
    return '${appDir.path}/bin';
  }

  Future<String> _appBinYtDlpPath() async {
    final binDir = await _appBinDirPath();
    final binaryName = Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';
    return '$binDir/$binaryName';
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
