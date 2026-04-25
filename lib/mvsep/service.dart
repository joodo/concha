import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '/mvsep/utils.dart';
import '/network/network.dart';
import '/preferences/preferences.dart';
import '/utils/json.dart';

import 'models.dart';

class MvsepException implements Exception {
  const MvsepException(this.response);
  final Response response;

  @override
  String toString() => response.data.toString();
}

class MvsepMaxConcurrencyReachedException extends MvsepException {
  const MvsepMaxConcurrencyReachedException(super.response);

  @override
  String toString() => response.data['data']['message'];
}

class MvsepJobNotFound extends MvsepException {
  const MvsepJobNotFound(super.response);
  String get message => response.data['data']['message'];
  @override
  String toString() => message;
}

class MvsepJobFailed extends MvsepException {
  const MvsepJobFailed(super.response);
  String get message => response.data['data']['message'];
  @override
  String toString() => message;
}

class MvsepUnknownJobResult extends MvsepException {
  const MvsepUnknownJobResult(super.response);
  String get algorithm => response.data['data']['algorithm'];
  @override
  String toString() => algorithm;
}

sealed class MvsepResult {
  const MvsepResult({required this.data});
  final JsonMap data;
}

class MvsepSeparationResult extends MvsepResult {
  const MvsepSeparationResult({
    required super.data,
    required this.vocalUrl,
    required this.instrumentUrl,
  });

  final Uri vocalUrl, instrumentUrl;
}

class MvsepTranscriptionResult extends MvsepResult {
  MvsepTranscriptionResult({required super.data, required this.lrc});
  final String lrc;
}

sealed class MvsepJobStatus {
  const MvsepJobStatus({this.message});
  final String? message;
}

class MvsepJobStatusWaiting extends MvsepJobStatus {
  const MvsepJobStatusWaiting({
    required this.queueCount,
    required this.currentOrder,
    super.message,
  });
  final int queueCount, currentOrder;
}

class MvsepJobStatusProcessing extends MvsepJobStatus {
  MvsepJobStatusProcessing({super.message});
}

class MvsepJobStatusDone extends MvsepJobStatus {
  MvsepJobStatusDone({super.message});
}

/// See [https://mvsep.com/en/full_api]
class MvsepService {
  static final _host = Uri.parse('https://mvsep.com');
  static const _pollInterval = Duration(seconds: 1);

  const MvsepService._();
  static MvsepService i = MvsepService._();

  Future<MvsepJob> createTranscriptionJob(
    String audioPath, {
    ProgressCallback? onUploadProgress,
  }) => _createJob(
    audioPath: audioPath,
    type: 39,
    opt1: '0',
    opt2: '0',
    onUploadProgress: onUploadProgress,
  );

  Future<MvsepJob> createSeparationJob(
    String audioPath, {
    ProgressCallback? onUploadProgress,
  }) => _createJob(
    audioPath: audioPath,
    type: 40,
    opt1: '81',
    onUploadProgress: onUploadProgress,
  );

  Future<MvsepJob> _createJob({
    required String audioPath,
    required int type,
    String? opt1,
    String? opt2,
    String? opt3,
    ProgressCallback? onUploadProgress,
  }) async {
    final token = Pref.get<String?>(.mvsepKey);
    if (token?.isNotEmpty != true) {
      throw StateError('Missing mvsepKey in preference.');
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      throw PathNotFoundException(
        audioPath,
        const OSError("No such file or directory", 2),
      );
    }

    final fileName = await _buildUploadFilename(audioPath);

    final formData = FormData.fromMap({
      'api_token': token,
      'sep_type': type.toString(),
      'add_opt1': ?opt1,
      'add_opt2': ?opt2,
      'add_opt3': ?opt3,
      'audiofile': await MultipartFile.fromFile(audioPath, filename: fileName),
    });

    try {
      final response = await http().postUri(
        _host.resolve('/api/separation/create'),
        data: formData,
        onSendProgress: onUploadProgress,
      );
      return MvsepJob.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        if (e.response == null) rethrow;

        try {
          final errors = (e.response!.data['errors'] as List)
              .map((e) => e as String)
              .toList();

          final maxConcurrencyReached =
              errors.length == 1 &&
              errors.first.toLowerCase().contains(
                'wait before adding new file',
              );
          if (!maxConcurrencyReached) rethrow;
        } catch (_) {
          throw MvsepException(e.response!);
        }
        throw MvsepMaxConcurrencyReachedException(e.response!);
      } else {
        rethrow;
      }
    }
  }

  Future<MvsepResult> waitMvsepJob(
    MvsepJob job, {
    void Function(MvsepJobStatus status)? onStatusChanged,
  }) async {
    late final Response resultResponse;
    pollLoop:
    while (true) {
      final response = await http().get(
        _host.resolve('/api/separation/get').toString(),
        queryParameters: {'hash': job.hash},
      );

      final status = response.data['status'] as String;
      final data = response.data['data'] as JsonMap;
      final message = data['message'] as String?;
      switch (status) {
        case 'not_found':
          throw MvsepJobNotFound(response);

        case 'failed':
          throw MvsepJobFailed(response);

        case 'waiting':
          onStatusChanged?.call(
            MvsepJobStatusWaiting(
              message: message,
              queueCount: data['queue_count'],
              currentOrder: data['current_order'],
            ),
          );

        case 'processing':
        case 'distributing':
        case 'merging':
          onStatusChanged?.call(MvsepJobStatusProcessing(message: message));

        case 'done':
          onStatusChanged?.call(MvsepJobStatusDone(message: message));
          resultResponse = response;
          break pollLoop;

        default:
          debugPrint('Unknown mvsep status "$status": $data');
      }

      await Future.delayed(_pollInterval);
    }

    final resultData = resultResponse.data['data'] as JsonMap;
    final algorithm = resultData['algorithm'] as String;
    switch (algorithm.toLowerCase()) {
      case String s when s.contains('bs roformer'):
        return _processSeparationResult(resultData);
      case String s when s.contains('whisper'):
        return _processTranscriptionResult(resultData);
      default:
        throw MvsepUnknownJobResult(resultResponse);
    }
  }

  Future<String> _buildUploadFilename(String filePath) async {
    final baseName = p.basename(filePath);
    final ext = await detectAudioExtension(filePath);
    if (ext == null) throw FormatException('Unsupported file format', filePath);
    return '$baseName$ext';
  }

  MvsepSeparationResult _processSeparationResult(JsonMap data) {
    final files = data['files'] as List;
    Uri extractUriFromData(String containedType) {
      final url =
          files.firstWhere((file) {
                final type = file['type'] as String;
                return type.toLowerCase().contains(containedType);
              })['url']
              as String;
      return Uri.parse(url);
    }

    return MvsepSeparationResult(
      data: data,
      vocalUrl: extractUriFromData('vocal'),
      instrumentUrl: extractUriFromData('other'),
    );
  }

  MvsepTranscriptionResult _processTranscriptionResult(JsonMap data) {
    final srt = data['transcription']['srt'] as String;
    final lrc = srtToLrc(srt);
    return MvsepTranscriptionResult(data: data, lrc: lrc);
  }
}
