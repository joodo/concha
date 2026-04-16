import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '/utils/utils.dart';

import 'network.dart';

typedef AcoustProgressHandler = void Function(String message);
typedef AcoustLogHandler = void Function(String line);

class AcoustIdResult {
  const AcoustIdResult({
    required this.raw,
    required this.title,
    required this.artist,
  });

  final Map<String, dynamic> raw;
  final String title;
  final String artist;
}

class AcoustIdService {
  AcoustIdService({ShellRunner? shellRunner})
    : _shellRunner = shellRunner ?? const ShellRunner();

  final ShellRunner _shellRunner;

  Future<AcoustIdResult> recognizeLocalFile({
    required String audioFilePath,
    required String apiKey,
    AcoustProgressHandler? onProgress,
    AcoustLogHandler? onLog,
  }) async {
    final audioFile = File(audioFilePath);
    if (!audioFile.existsSync()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final key = apiKey.trim();
    if (key.isEmpty) {
      throw Exception('AcoustID API Key 不能为空');
    }

    onProgress?.call('检查 fpcalc');
    final fpcalcPath = await _ensureFpcalc(
      onProgress: onProgress,
      onLog: onLog,
    );

    onProgress?.call('使用 fpcalc 生成指纹');
    final fpcalcCommand =
        '${ShellRunner.quote(fpcalcPath)} -json ${ShellRunner.quote(audioFilePath)}';
    onLog?.call('[shell] $fpcalcCommand');
    final fpcalcResult = await _shellRunner.run(
      fpcalcCommand,
      onOutput: (output) => onLog?.call('[${output.tag}] ${output.line}'),
    );
    if (fpcalcResult.exitCode != 0) {
      throw Exception('fpcalc 执行失败，退出码 ${fpcalcResult.exitCode}');
    }

    final fingerprintPayload = _extractFpcalcPayload(fpcalcResult.allOutput);
    final fingerprint =
        fingerprintPayload['fingerprint']?.toString().trim() ?? '';
    final duration = _parseDuration(fingerprintPayload['duration']);

    if (fingerprint.isEmpty) {
      throw Exception('未从 fpcalc 输出中解析到 fingerprint');
    }
    if (duration == null || duration <= 0) {
      throw Exception('未从 fpcalc 输出中解析到有效 duration');
    }

    onProgress?.call('请求 AcoustID API');
    const requestUrl = 'https://api.acoustid.org/v2/lookup';
    final form = <String, String>{
      'client': key,
      'clientversion': '2.13.3.final0',
      'format': 'json',
      'meta': 'recordings releases',
      'duration': duration.toString(),
      'fingerprint': fingerprint,
    };

    onLog?.call('[http] POST $requestUrl');
    onLog?.call(
      '[http] form duration=$duration fingerprint_len=${fingerprint.length}',
    );

    final response = await http()
        .headers(const {
          'Accept': 'application/json',
          'User-Agent':
              'MusicBrainz-Picard/2.13.3.final0 (macOS; Concha compatibility mode)',
        })
        .post(requestUrl, data: FormData.fromMap(form));

    final body = response.data;
    if (body['status']?.toString() != 'ok') {
      final error = body['error']?.toString() ?? '未知错误';
      throw Exception('AcoustID 返回失败: $error');
    }

    final results = body['results'];
    if (results is! List || results.isEmpty) {
      throw Exception('AcoustID 未返回匹配结果');
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

    Map<String, dynamic>? bestRecording;
    double bestScore = 0.0;
    for (final item in resultMaps) {
      final itemScore = (item['score'] is num)
          ? (item['score'] as num).toDouble()
          : 0.0;
      final recordings = item['recordings'];
      if (recordings is! List || recordings.isEmpty) {
        continue;
      }

      for (final recording in recordings.whereType<Map<String, dynamic>>()) {
        final title = recording['title']?.toString().trim() ?? '';
        if (title.isEmpty) continue;
        bestRecording = recording;
        bestScore = itemScore;
        break;
      }

      if (bestRecording != null) break;
    }

    if (bestRecording == null) {
      throw Exception('AcoustID 返回结果中没有可用 recording');
    }

    onLog?.call('[acoustid] best_score=$bestScore');
    final title = bestRecording['title']?.toString() ?? '未知标题';
    final artist = _extractArtist(bestRecording);

    return AcoustIdResult(raw: body, title: title, artist: artist);
  }

  Future<String> _ensureFpcalc({
    AcoustProgressHandler? onProgress,
    AcoustLogHandler? onLog,
  }) async {
    final localFpcalcPath = await _appBinFpcalcPath();
    if (await File(localFpcalcPath).exists()) {
      onLog?.call('[tool] 使用本地 fpcalc: $localFpcalcPath');
      return localFpcalcPath;
    }

    if (await _shellRunner.existsInPath('fpcalc')) {
      onLog?.call('[tool] 使用系统 fpcalc');
      return 'fpcalc';
    }

    onLog?.call('[tool] 未在 PATH 中找到 fpcalc');
    onProgress?.call('未找到 fpcalc，开始从官网下载安装包');
    return _downloadPrebuiltFpcalc(onLog: onLog);
  }

  Future<String> _downloadPrebuiltFpcalc({AcoustLogHandler? onLog}) async {
    final targetPath = await _appBinFpcalcPath();
    final binDir = Directory(await _appBinDirPath());
    if (!await binDir.exists()) {
      await binDir.create(recursive: true);
    }

    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      onLog?.call('[tool] 使用 appSupportDir/bin 中已下载的 fpcalc: $targetPath');
      return targetPath;
    }

    final tempDir = await Directory.systemTemp.createTemp('concha-fpcalc-');
    try {
      final archivePath = '${tempDir.path}/fpcalc.tar.gz';

      for (final url in _candidateFpcalcUrls()) {
        onLog?.call('[download] $url');

        try {
          await http().download(url, archivePath);
        } catch (e) {
          onLog?.call('[download] $e, skip');
          continue;
        }

        final extractCommand =
            'tar -xzf ${ShellRunner.quote(archivePath)} -C ${ShellRunner.quote(tempDir.path)}';
        onLog?.call('[shell] $extractCommand');
        final extractResult = await _shellRunner.run(
          extractCommand,
          onOutput: (output) => onLog?.call('[${output.tag}] ${output.line}'),
        );
        if (extractResult.exitCode != 0) {
          onLog?.call('[download] 解压失败，尝试下一个包');
          continue;
        }

        final extracted = await _findFpcalcBinary(tempDir);
        if (extracted == null) {
          onLog?.call('[download] 未在解压目录找到 fpcalc');
          continue;
        }

        await File(extracted).copy(targetPath);
        final chmod = await _shellRunner.run(
          'chmod +x ${ShellRunner.quote(targetPath)}',
        );
        if (chmod.exitCode != 0) {
          throw Exception('下载后设置 fpcalc 可执行权限失败');
        }

        onLog?.call('[tool] 已下载 fpcalc 到 appSupportDir/bin: $targetPath');
        return targetPath;
      }
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }

    throw Exception('自动下载 fpcalc 失败，请检查网络/代理，或手动安装 fpcalc');
  }

  List<String> _candidateFpcalcUrls() {
    if (Platform.isMacOS) {
      return const [
        'https://github.com/acoustid/chromaprint/releases/download/v1.6.0/chromaprint-fpcalc-1.6.0-macos-universal.tar.gz',
        'https://github.com/acoustid/chromaprint/releases/download/v1.6.0/chromaprint-fpcalc-1.6.0-macos-arm64.tar.gz',
        'https://github.com/acoustid/chromaprint/releases/download/v1.6.0/chromaprint-fpcalc-1.6.0-macos-x86_64.tar.gz',
        'https://github.com/acoustid/chromaprint/releases/download/v1.6.0/chromaprint-fpcalc-1.6.0-darwin-arm64.tar.gz',
        'https://github.com/acoustid/chromaprint/releases/download/v1.6.0/chromaprint-fpcalc-1.6.0-darwin-x86_64.tar.gz',
        'https://github.com/acoustid/chromaprint/releases/download/v1.5.1/chromaprint-fpcalc-1.5.1-macos-universal.tar.gz',
      ];
    }

    if (Platform.isLinux) {
      return const [
        'https://github.com/acoustid/chromaprint/releases/download/v1.6.0/chromaprint-fpcalc-1.6.0-linux-x86_64.tar.gz',
        'https://github.com/acoustid/chromaprint/releases/download/v1.5.1/chromaprint-fpcalc-1.5.1-linux-x86_64.tar.gz',
      ];
    }

    return const [];
  }

  Future<String> _appBinDirPath() async {
    final appDir = await getApplicationSupportDirectory();
    return '${appDir.path}/bin';
  }

  Future<String> _appBinFpcalcPath() async {
    final binDir = await _appBinDirPath();
    final binaryName = Platform.isWindows ? 'fpcalc.exe' : 'fpcalc';
    return '$binDir/$binaryName';
  }

  Future<String?> _findFpcalcBinary(Directory root) async {
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.isEmpty
          ? ''
          : entity.uri.pathSegments.last;
      if (name == 'fpcalc' || name == 'fpcalc.exe') {
        return entity.path;
      }
    }
    return null;
  }

  Map<String, dynamic> _extractFpcalcPayload(String output) {
    final text = output.trim();
    if (text.isEmpty) {
      throw Exception('fpcalc 没有输出');
    }

    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    if (firstBrace < 0 || lastBrace <= firstBrace) {
      throw Exception('fpcalc 输出不包含 JSON: $text');
    }

    final jsonText = text.substring(firstBrace, lastBrace + 1);
    final payload = jsonDecode(jsonText);
    if (payload is! Map<String, dynamic>) {
      throw Exception('fpcalc JSON 结构异常');
    }

    return payload;
  }

  int? _parseDuration(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final intValue = int.tryParse(value);
      if (intValue != null) return intValue;
      final doubleValue = double.tryParse(value);
      return doubleValue?.round();
    }
    return null;
  }

  String _extractArtist(Map<String, dynamic> recording) {
    final artists = recording['artists'];
    if (artists is! List || artists.isEmpty) {
      return '未知艺术家';
    }

    final firstArtist = artists.first;
    if (firstArtist is! Map<String, dynamic>) {
      return '未知艺术家';
    }

    return firstArtist['name']?.toString() ?? '未知艺术家';
  }
}
