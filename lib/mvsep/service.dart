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

/// See [https://mvsep.com/en/full_api]
class MvsepService {
  static final _host = Uri.parse('https://mvsep.com');
  static const _pollInterval = Duration(seconds: 1);

  const MvsepService._();
  static MvsepService i = MvsepService._();

  Future<MvsepJob> createSeparationJob(
    String audioPath, {
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
      'sep_type': '40',
      'add_opt1': '81',
      'output_format': '0',
      'is_demo': '0',
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
        return MvsepSeparationResult(data: resultData);
      default:
        throw MvsepUnknownJobResult(resultResponse);
    }
  }

  Future<String> _buildUploadFilename(String filePath) async {
    final baseName = p.basename(filePath);
    final normalizedBaseName = baseName.trim().isEmpty ? 'audio' : baseName;
    if (p.extension(normalizedBaseName).isNotEmpty) {
      return normalizedBaseName;
    }

    final ext = await detectAudioExtension(filePath);
    if (ext == null) throw FormatException('Unsupported file format', filePath);
    return '$normalizedBaseName$ext';
  }
}
