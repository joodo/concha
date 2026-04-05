import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../preferences/preferences.dart';
import '../utils/http.dart';

sealed class MvsepTaskEvent {
  const MvsepTaskEvent();
}

class MvsepInitEvent extends MvsepTaskEvent {
  const MvsepInitEvent();
}

class MvsepLocalQueuedEvent extends MvsepTaskEvent {
  const MvsepLocalQueuedEvent({
    required this.audioPath,
    required this.localQueuePosition,
    required this.localQueueSize,
    required this.attachedToExistingTask,
  });

  final String audioPath;
  final int localQueuePosition;
  final int localQueueSize;
  final bool attachedToExistingTask;
}

class MvsepLocalRunningEvent extends MvsepTaskEvent {
  const MvsepLocalRunningEvent({
    required this.audioPath,
    required this.attachedToExistingTask,
  });

  final String audioPath;
  final bool attachedToExistingTask;
}

class MvsepUploadingEvent extends MvsepTaskEvent {
  const MvsepUploadingEvent({
    required this.audioPath,
    required this.uploadedBytes,
    required this.totalBytes,
  });

  final String audioPath;
  final int uploadedBytes;
  final int totalBytes;

  double? get progressPercent {
    if (totalBytes <= 0) {
      return null;
    }
    return uploadedBytes * 100 / totalBytes;
  }
}

class MvsepRemoteQueuedEvent extends MvsepTaskEvent {
  const MvsepRemoteQueuedEvent({
    required this.audioPath,
    required this.remoteStatus,
    this.remoteQueueCount,
    this.remoteCurrentOrder,
  });

  final String audioPath;
  final String remoteStatus;
  final int? remoteQueueCount;
  final int? remoteCurrentOrder;
}

class MvsepRemoteProcessingEvent extends MvsepTaskEvent {
  const MvsepRemoteProcessingEvent({
    required this.audioPath,
    required this.remoteStatus,
  });

  final String audioPath;
  final String remoteStatus;
}

class MvsepDownloadingEvent extends MvsepTaskEvent {
  const MvsepDownloadingEvent({
    required this.audioPath,
    required this.vocalUrl,
    required this.instruUrl,
    required this.vocalDownloadedBytes,
    required this.instruDownloadedBytes,
    this.vocalFileBytes,
    this.instruFileBytes,
  });

  final String audioPath;
  final String vocalUrl;
  final String instruUrl;
  final int vocalDownloadedBytes;
  final int instruDownloadedBytes;
  int get totalDownloadedBytes => vocalDownloadedBytes + instruDownloadedBytes;
  final int? vocalFileBytes;
  final int? instruFileBytes;
}

class MvsepCompletedEvent extends MvsepTaskEvent {
  const MvsepCompletedEvent({
    required this.audioPath,
    this.hash,
    this.algorithmId,
    this.algorithmName,
    required this.vocalPath,
    required this.instruPath,
    this.vocalFileBytes,
    this.instruFileBytes,
  });

  final String audioPath;
  final String? hash;
  final int? algorithmId;
  final String? algorithmName;
  final String vocalPath;
  final String instruPath;
  final int? vocalFileBytes;
  final int? instruFileBytes;
}

class MvsepFailedEvent extends MvsepTaskEvent {
  const MvsepFailedEvent({
    required this.audioPath,
    required this.error,
    required this.phase,
  });

  final String audioPath;
  final String error;
  final String phase;
}

class MvsepSeparationService {
  MvsepSeparationService._internal();
  static final MvsepSeparationService _instance =
      MvsepSeparationService._internal();
  static MvsepSeparationService get i => _instance;

  static const String _apiBase = 'https://mvsep.com/api';
  static const Duration _pollInterval = Duration(seconds: 3);
  static const String _statusWaiting = 'waiting';
  static const int _maxErrorPreviewChars = 800;
  static const int _fixedSepType = 40;
  static const String _fixedAlgorithmName =
      'BS Roformer (vocals, instrumental)';
  static const String _fixedAddOpt1 = '81';

  String? get _proxy => Pref.normalizedProxy;

  String get _mvsepToken {
    final raw = Pref.i.get(PrefKeys.mvsepKey.value);
    final token = raw is String ? raw.trim() : '';
    if (token.isEmpty) {
      throw StateError('MVSEP API key is empty.');
    }
    return token;
  }

  final Queue<_SeparationJob> _localQueue = Queue<_SeparationJob>();
  final Map<String, _SeparationJob> _activeByAudioPath =
      <String, _SeparationJob>{};
  bool _isWorkerRunning = false;
  bool _isDisposed = false;

  final Map<String, _TaskRecord> _records = <String, _TaskRecord>{};
  bool _storeLoaded = false;

  /// Starts or reuses an audio separation task and returns its event stream.
  ///
  /// If files already exist at [saveVocalPath] or [saveInstruPath], the method
  /// does not skip writing. The latest separation result will overwrite them.
  ///
  /// - Local completed cache hit: copies cached files to target paths (overwrite), then emits [MvsepCompletedEvent].
  /// - Remote task completed: downloads to cache, then copies to target paths (overwrite).
  /// - Copy/write failure: reports failure via [MvsepFailedEvent].
  Stream<MvsepTaskEvent> separate({
    required String audioPath,
    required String saveVocalPath,
    required String saveInstruPath,
  }) {
    if (_isDisposed) {
      throw StateError('MvsepSeparationService is disposed.');
    }

    final controller = StreamController<MvsepTaskEvent>.broadcast();
    _emitToController(controller, const MvsepInitEvent());

    unawaited(
      _separateAsync(
        audioPath: audioPath,
        saveVocalPath: saveVocalPath,
        saveInstruPath: saveInstruPath,
        controller: controller,
      ),
    );

    return controller.stream;
  }

  Future<void> _separateAsync({
    required String audioPath,
    required String saveVocalPath,
    required String saveInstruPath,
    required StreamController<MvsepTaskEvent> controller,
  }) async {
    var eventAudioPath = audioPath;
    try {
      await _ensureStoreLoaded();

      final audioPathKey = _normalizePath(audioPath);
      eventAudioPath = audioPathKey;
      final vocalPath = _normalizePath(saveVocalPath);
      final instruPath = _normalizePath(saveInstruPath);
      final listener = _JobListener(
        stream: controller,
        saveVocalPath: vocalPath,
        saveInstruPath: instruPath,
      );

      final existingRecord = _records[audioPathKey];
      if (existingRecord != null && existingRecord.isCompleted) {
        try {
          await _copyCachedResultToTargets(
            record: existingRecord,
            saveVocalPath: vocalPath,
            saveInstruPath: instruPath,
          );

          _emitToController(
            controller,
            MvsepCompletedEvent(
              audioPath: audioPathKey,
              hash: existingRecord.hash,
              algorithmId: existingRecord.algorithmId,
              algorithmName: existingRecord.algorithmName,
              vocalPath: vocalPath,
              instruPath: instruPath,
              vocalFileBytes: await _safeFileSize(vocalPath),
              instruFileBytes: await _safeFileSize(instruPath),
            ),
          );
          await controller.close();
        } catch (e) {
          _emitToController(
            controller,
            MvsepFailedEvent(
              audioPath: audioPathKey,
              error: 'Failed to use cached result: $e',
              phase: 'cache_load',
            ),
          );
          await controller.close();
        }

        return;
      }

      final existingJob = _activeByAudioPath[audioPathKey];
      if (existingJob != null) {
        existingJob.listeners.add(listener);
        _emitLocalPosition(existingJob);
        return;
      }

      final record =
          existingRecord ?? _TaskRecord.empty(audioPath: audioPathKey);
      record.touch(status: _TaskRecordStatus.localQueued);
      _records[audioPathKey] = record;
      await _persistStore();

      final job = _SeparationJob(
        audioPath: audioPathKey,
        listeners: <_JobListener>[listener],
      );
      _activeByAudioPath[audioPathKey] = job;
      _localQueue.add(job);
      _notifyQueuePositionChanged();

      unawaited(_runWorker());
    } catch (e) {
      _emitToController(
        controller,
        MvsepFailedEvent(
          audioPath: eventAudioPath,
          error: e.toString(),
          phase: 'separate_init',
        ),
      );
      await controller.close();
    }
  }

  Future<void> deleteCacheByAudioPath(String audioPath) async {
    await _ensureStoreLoaded();
    final key = _normalizePath(audioPath);

    final active = _activeByAudioPath.remove(key);
    if (active != null) {
      _localQueue.remove(active);
      for (final listener in active.listeners) {
        _emitToController(
          listener.stream,
          MvsepFailedEvent(
            audioPath: key,
            error: 'Task canceled due to cache deletion.',
            phase: 'local_queue_cancelled',
          ),
        );
        await listener.stream.close();
      }
    }

    final record = _records.remove(key);
    if (record != null) {
      await _deleteFileIfExists(record.vocalCachePath);
      await _deleteFileIfExists(record.instruCachePath);
      await _persistStore();
    }

    _notifyQueuePositionChanged();
  }

  Future<void> dispose() async {
    _isDisposed = true;
    for (final job in _activeByAudioPath.values) {
      for (final listener in job.listeners) {
        if (!listener.stream.isClosed) {
          await listener.stream.close();
        }
      }
    }
    _activeByAudioPath.clear();
    _localQueue.clear();
  }

  Future<void> _runWorker() async {
    if (_isWorkerRunning || _isDisposed) {
      return;
    }

    _isWorkerRunning = true;
    try {
      while (_localQueue.isNotEmpty && !_isDisposed) {
        final job = _localQueue.removeFirst();
        _notifyQueuePositionChanged();
        await _processJob(job);
      }
    } finally {
      _isWorkerRunning = false;
    }
  }

  Future<void> _processJob(_SeparationJob job) async {
    final record =
        _records[job.audioPath] ?? _TaskRecord.empty(audioPath: job.audioPath);
    _records[job.audioPath] = record;

    try {
      final token = _mvsepToken;
      record.touch(status: _TaskRecordStatus.localRunning);
      await _persistStore();
      _emitToJob(
        job,
        MvsepLocalRunningEvent(
          audioPath: job.audioPath,
          attachedToExistingTask: false,
        ),
      );

      if (record.isCompleted) {
        await _finalizeFromCache(job, record);
        return;
      }

      record.algorithmId = _fixedSepType;
      record.algorithmName = _fixedAlgorithmName;

      var currentUploadedBytes = 0;
      var currentUploadTotalBytes = 0;
      var lastUploadEventAt = DateTime.fromMillisecondsSinceEpoch(0);
      void emitUploadProgress(
        int uploadedBytes,
        int totalBytes, {
        bool force = false,
      }) {
        currentUploadedBytes = uploadedBytes;
        currentUploadTotalBytes = totalBytes;
        final now = DateTime.now();
        if (!force &&
            now.difference(lastUploadEventAt) < const Duration(seconds: 1)) {
          return;
        }
        lastUploadEventAt = now;
        _emitToJob(
          job,
          MvsepUploadingEvent(
            audioPath: job.audioPath,
            uploadedBytes: uploadedBytes,
            totalBytes: totalBytes,
          ),
        );
      }

      // Always create a fresh remote task for non-completed records.
      // Reusing persisted hash can point to an old task created with wrong params.
      final hash = await _createSeparation(
        token: token,
        audioPath: job.audioPath,
        sepType: _fixedSepType,
        addOpt1: _fixedAddOpt1,
        onUploadProgress: (uploadedBytes, totalBytes) {
          emitUploadProgress(uploadedBytes, totalBytes);
        },
      );

      emitUploadProgress(
        currentUploadedBytes,
        currentUploadTotalBytes,
        force: true,
      );

      record.hash = hash;
      record.touch(status: _TaskRecordStatus.remoteWaiting);
      await _persistStore();

      while (!_isDisposed) {
        final pollResult = await _getSeparationStatus(hash);
        final status = pollResult.status.toLowerCase();
        record.lastRemoteStatus = status;
        record.lastRemoteData = pollResult.data;

        if (status == _statusWaiting) {
          record.touch(status: _TaskRecordStatus.remoteWaiting);
          await _persistStore();
          _emitToJob(
            job,
            MvsepRemoteQueuedEvent(
              audioPath: job.audioPath,
              remoteStatus: status,
              remoteQueueCount: _extractIntByKeys(
                pollResult.data,
                const <String>['queue_count', 'queueCount'],
              ),
              remoteCurrentOrder: _extractIntByKeys(
                pollResult.data,
                const <String>['current_order', 'currentOrder'],
              ),
            ),
          );
          await Future<void>.delayed(_pollInterval);
          continue;
        }

        if (_isProcessingStatus(status)) {
          record.touch(status: _TaskRecordStatus.remoteProcessing);
          await _persistStore();
          _emitToJob(
            job,
            MvsepRemoteProcessingEvent(
              audioPath: job.audioPath,
              remoteStatus: status,
            ),
          );
          await Future<void>.delayed(_pollInterval);
          continue;
        }

        if (_isCompletedStatus(status)) {
          final outputUrls = _extractStemUrlsFromPollResult(pollResult);
          if (outputUrls.vocalUrl == null || outputUrls.instruUrl == null) {
            final remoteAlgorithm =
                _asString(pollResult.data['algorithm']) ??
                _asString(pollResult.raw['algorithm']) ??
                _asString(_asMap(pollResult.raw['data'])?['algorithm']) ??
                '<unknown>';
            throw StateError(
              'MVSEP returned completed status but stem URLs were not found. '
              'status=$status algorithm=$remoteAlgorithm selected_sep_type=$_fixedSepType '
              'raw_preview=${_previewObjectForError(pollResult.raw)}',
            );
          }

          final vocalUrl = outputUrls.vocalUrl!;
          final instruUrl = outputUrls.instruUrl!;

          final cachePaths = await _cachePathsForHash(hash);
          var vocalDownloadedBytes = 0;
          var instruDownloadedBytes = 0;
          int? vocalFileBytes;
          int? instruFileBytes;
          var lastProgressEventAt = DateTime.fromMillisecondsSinceEpoch(0);

          void emitDownloadProgress({bool force = false}) {
            final now = DateTime.now();
            if (!force &&
                now.difference(lastProgressEventAt) <
                    const Duration(seconds: 1)) {
              return;
            }
            lastProgressEventAt = now;
            _emitToJob(
              job,
              MvsepDownloadingEvent(
                audioPath: job.audioPath,
                vocalUrl: vocalUrl,
                instruUrl: instruUrl,
                vocalDownloadedBytes: vocalDownloadedBytes,
                instruDownloadedBytes: instruDownloadedBytes,
                vocalFileBytes: vocalFileBytes,
                instruFileBytes: instruFileBytes,
              ),
            );
          }

          emitDownloadProgress(force: true);

          final vocalFuture = _downloadToPath(
            url: vocalUrl,
            savePath: cachePaths.vocalPath,
            onProgress: (downloadedBytes, totalBytes) {
              vocalDownloadedBytes = downloadedBytes;
              if (totalBytes != null && totalBytes > 0) {
                vocalFileBytes = totalBytes;
              }
              emitDownloadProgress();
            },
          );
          final instruFuture = _downloadToPath(
            url: instruUrl,
            savePath: cachePaths.instruPath,
            onProgress: (downloadedBytes, totalBytes) {
              instruDownloadedBytes = downloadedBytes;
              if (totalBytes != null && totalBytes > 0) {
                instruFileBytes = totalBytes;
              }
              emitDownloadProgress();
            },
          );

          final downloadResults = await Future.wait<int>(<Future<int>>[
            vocalFuture,
            instruFuture,
          ]);
          final vocalBytes = downloadResults[0];
          final instruBytes = downloadResults[1];
          vocalDownloadedBytes = vocalBytes;
          instruDownloadedBytes = instruBytes;
          emitDownloadProgress(force: true);

          record
            ..vocalCachePath = cachePaths.vocalPath
            ..instruCachePath = cachePaths.instruPath;
          record.touch(status: _TaskRecordStatus.completed);
          await _persistStore();

          await _finalizeFromCache(job, record);
          return;
        }

        if (_isFailedStatus(status)) {
          throw StateError('MVSEP task failed with status: $status');
        }

        record.touch(status: _TaskRecordStatus.remoteProcessing);
        await _persistStore();
        _emitToJob(
          job,
          MvsepRemoteProcessingEvent(
            audioPath: job.audioPath,
            remoteStatus: status,
          ),
        );
        await Future<void>.delayed(_pollInterval);
      }
    } catch (e) {
      final failureRecord = _records[job.audioPath];
      if (failureRecord != null) {
        failureRecord.touch(status: _TaskRecordStatus.failed);
        failureRecord.lastError = e.toString();
        await _persistStore();
      }

      _emitToJob(
        job,
        MvsepFailedEvent(
          audioPath: job.audioPath,
          error: e.toString(),
          phase: 'process_job',
        ),
      );
      await _closeJobListeners(job);
    } finally {
      _activeByAudioPath.remove(job.audioPath);
    }
  }

  Future<void> _finalizeFromCache(
    _SeparationJob job,
    _TaskRecord record,
  ) async {
    for (final listener in job.listeners) {
      await _copyCachedResultToTargets(
        record: record,
        saveVocalPath: listener.saveVocalPath,
        saveInstruPath: listener.saveInstruPath,
      );

      _emitToController(
        listener.stream,
        MvsepCompletedEvent(
          audioPath: job.audioPath,
          hash: record.hash,
          algorithmId: record.algorithmId,
          algorithmName: record.algorithmName,
          vocalPath: listener.saveVocalPath,
          instruPath: listener.saveInstruPath,
          vocalFileBytes: await _safeFileSize(listener.saveVocalPath),
          instruFileBytes: await _safeFileSize(listener.saveInstruPath),
        ),
      );
      await listener.stream.close();
    }
  }

  Future<void> _copyCachedResultToTargets({
    required _TaskRecord record,
    required String saveVocalPath,
    required String saveInstruPath,
  }) async {
    final vocalCache = record.vocalCachePath;
    final instruCache = record.instruCachePath;
    if (vocalCache == null || instruCache == null) {
      throw StateError('Cached stem paths are missing.');
    }

    await _copyFile(vocalCache, saveVocalPath);
    await _copyFile(instruCache, saveInstruPath);
  }

  Future<void> _copyFile(String src, String dst) async {
    final srcFile = File(src);
    if (!await srcFile.exists()) {
      throw StateError('Cache file not found: $src');
    }
    final dstFile = File(dst);
    await dstFile.parent.create(recursive: true);
    await srcFile.copy(dst);
  }

  Future<String> _createSeparation({
    required String token,
    required String audioPath,
    required int sepType,
    required String addOpt1,
    void Function(int uploadedBytes, int totalBytes)? onUploadProgress,
  }) async {
    final uri = Uri.parse('$_apiBase/separation/create');

    final fields = <String, String>{
      'api_token': token,
      'sep_type': sepType.toString(),
      'add_opt1': addOpt1,
      'output_format': '0',
      'is_demo': '0',
    };
    final uploadFilename = await _buildUploadFilename(audioPath);

    final responseBody = await _postMultipart(
      uri: uri,
      fields: fields,
      fileFieldCandidates: const <String>['audiofile'],
      filePath: audioPath,
      uploadFilename: uploadFilename,
      onUploadProgress: onUploadProgress,
    );

    final hash = _extractHashFromAny(responseBody);
    if (hash != null && hash.isNotEmpty) {
      return hash;
    }

    throw StateError('Hash not found in create response from ${uri.path}.');
  }

  Future<_PollResult> _getSeparationStatus(String hash) async {
    final attempts = <Uri>[
      Uri.parse(
        '$_apiBase/separation/get',
      ).replace(queryParameters: <String, String>{'hash': hash}),
    ];

    Object? lastError;
    for (final uri in attempts) {
      try {
        final response = await Http.get(uri.toString(), proxy: _proxy);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          lastError = StateError('HTTP ${response.statusCode} at ${uri.path}');
          continue;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          lastError = StateError(
            'Unexpected status response shape at ${uri.path}',
          );
          continue;
        }

        final status = _extractRemoteStatus(decoded);
        final data = _asMap(decoded['data']) ?? <String, dynamic>{};
        return _PollResult(status: status, data: data, raw: decoded);
      } catch (e) {
        lastError = e;
      }
    }

    throw StateError('Unable to poll MVSEP status: $lastError');
  }

  String _extractRemoteStatus(Map<String, dynamic> decoded) {
    final statusCandidate =
        _asString(decoded['status']) ??
        _asString(decoded['state']) ??
        _asString(decoded['message']);
    if (statusCandidate != null && statusCandidate.trim().isNotEmpty) {
      return statusCandidate;
    }

    final data = _asMap(decoded['data']);
    final fromFiles = _extractStemUrlsFromFiles(data?['files']);
    if (fromFiles.vocalUrl != null || fromFiles.instruUrl != null) {
      return 'completed';
    }

    return 'processing';
  }

  _StemUrls _extractStemUrlsFromPollResult(_PollResult pollResult) {
    final fromFiles = _extractStemUrlsFromFiles(pollResult.data['files']);
    if (fromFiles.vocalUrl != null && fromFiles.instruUrl != null) {
      return fromFiles;
    }

    final fromData = _extractStemUrls(pollResult.data);
    if (fromData.vocalUrl != null && fromData.instruUrl != null) {
      return fromData;
    }

    return _extractStemUrls(pollResult.raw);
  }

  _StemUrls _extractStemUrlsFromFiles(Object? files) {
    if (files is! List) {
      return const _StemUrls(vocalUrl: null, instruUrl: null);
    }

    String? vocalUrl;
    String? instruUrl;
    final allUrls = <String>[];
    for (final item in files) {
      if (item is! Map) {
        continue;
      }
      final map = item.cast<String, dynamic>();
      final url = _asString(map['url']);
      if (url == null || !_looksLikeAudioUrl(url)) {
        continue;
      }

      allUrls.add(url);
      final descriptor =
          '${_asString(map['download']) ?? ''} ${_asString(map['name']) ?? ''} ${_asString(map['type']) ?? ''}'
              .toLowerCase();

      if (vocalUrl == null &&
          (descriptor.contains('vocal') || descriptor.contains('voice'))) {
        vocalUrl = url;
        continue;
      }
      if (instruUrl == null &&
          (descriptor.contains('instrum') ||
              descriptor.contains('instrument') ||
              descriptor.contains('other') ||
              descriptor.contains('music'))) {
        instruUrl = url;
      }
    }

    if ((vocalUrl == null || instruUrl == null) && allUrls.length >= 2) {
      vocalUrl ??= allUrls.firstWhere(
        (url) =>
            url.toLowerCase().contains('vocal') ||
            url.toLowerCase().contains('voice'),
        orElse: () => allUrls.first,
      );
      instruUrl ??= allUrls.firstWhere(
        (url) =>
            url.toLowerCase().contains('instrum') ||
            url.toLowerCase().contains('instrument') ||
            url.toLowerCase().contains('other') ||
            url.toLowerCase().contains('music'),
        orElse: () => allUrls.length > 1 ? allUrls[1] : allUrls.first,
      );
    }

    return _StemUrls(vocalUrl: vocalUrl, instruUrl: instruUrl);
  }

  _StemUrls _extractStemUrls(Map<String, dynamic> data) {
    final discovered = <_NamedUrl>[];
    _collectUrls(data, <String>[], discovered);

    String? vocalUrl;
    String? instruUrl;
    for (final named in discovered) {
      final key = named.keyPath.toLowerCase();
      final url = named.url.toLowerCase();
      if (vocalUrl == null &&
          (key.contains('vocal') ||
              key.contains('voice') ||
              url.contains('vocal'))) {
        vocalUrl = named.url;
        continue;
      }
      if (instruUrl == null &&
          (key.contains('instrum') ||
              key.contains('instrument') ||
              key.endsWith('other') ||
              url.contains('instrum') ||
              url.contains('instrument'))) {
        instruUrl = named.url;
      }
    }

    if (vocalUrl == null || instruUrl == null) {
      final urls = discovered.map((item) => item.url).toSet().toList();
      urls.sort();
      if (urls.length >= 2) {
        vocalUrl ??= urls.firstWhere(
          (url) =>
              url.toLowerCase().contains('vocal') ||
              url.toLowerCase().contains('voice'),
          orElse: () => urls.first,
        );
        instruUrl ??= urls.firstWhere(
          (url) =>
              url.toLowerCase().contains('instrum') ||
              url.toLowerCase().contains('instrument'),
          orElse: () => urls.length > 1 ? urls[1] : urls.first,
        );
      }
    }

    return _StemUrls(vocalUrl: vocalUrl, instruUrl: instruUrl);
  }

  void _collectUrls(
    Object? value,
    List<String> keySegments,
    List<_NamedUrl> output,
  ) {
    if (value is Map) {
      value.forEach((k, v) {
        final key = k.toString();
        _collectUrls(v, <String>[...keySegments, key], output);
      });
      return;
    }

    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        _collectUrls(value[i], <String>[...keySegments, '$i'], output);
      }
      return;
    }

    if (value is String && _looksLikeAudioUrl(value)) {
      output.add(_NamedUrl(keyPath: keySegments.join('.'), url: value));
    }
  }

  bool _looksLikeAudioUrl(String value) {
    final lower = value.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return false;
    }

    return lower.contains('.mp3') ||
        lower.contains('.wav') ||
        lower.contains('.m4a') ||
        lower.contains('.flac') ||
        lower.contains('.ogg') ||
        lower.contains('.opus') ||
        lower.contains('.aac') ||
        lower.contains('.webm');
  }

  Future<_CachePaths> _cachePathsForHash(String hash) async {
    final baseDir = await _mvsepBaseDir();
    final hashDir = Directory(
      p.join(baseDir.path, 'cache', _sanitizeHash(hash)),
    );
    await hashDir.create(recursive: true);

    return _CachePaths(
      vocalPath: p.join(hashDir.path, 'vocals.mp3'),
      instruPath: p.join(hashDir.path, 'instrumental.mp3'),
    );
  }

  String _sanitizeHash(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  Future<int> _downloadToPath({
    required String url,
    required String savePath,
    void Function(int downloadedBytes, int? totalBytes)? onProgress,
  }) async {
    final client = Http.createClient(proxy: _proxy);
    IOSink? sink;
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Download failed: HTTP ${response.statusCode} for $url',
        );
      }
      final contentLength = response.contentLength;
      final totalBytes = (contentLength != null && contentLength > 0)
          ? contentLength
          : null;

      final file = File(savePath);
      await file.parent.create(recursive: true);
      sink = file.openWrite();

      var downloadedBytes = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        onProgress?.call(downloadedBytes, totalBytes);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      return downloadedBytes;
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {
        // Ignore close failure in error path.
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<dynamic> _postMultipart({
    required Uri uri,
    required Map<String, String> fields,
    required List<String> fileFieldCandidates,
    required String filePath,
    required String uploadFilename,
    void Function(int uploadedBytes, int totalBytes)? onUploadProgress,
  }) async {
    final client = Http.createClient(proxy: _proxy);
    try {
      Object? lastError;
      for (final fieldName in fileFieldCandidates) {
        try {
          final file = File(filePath);
          final totalBytes = await file.length();
          var uploadedBytes = 0;

          final uploadStream = file.openRead().transform(
            StreamTransformer<List<int>, List<int>>.fromHandlers(
              handleData: (chunk, sink) {
                uploadedBytes += chunk.length;
                onUploadProgress?.call(uploadedBytes, totalBytes);
                sink.add(chunk);
              },
            ),
          );

          onUploadProgress?.call(0, totalBytes);

          final request = http.MultipartRequest('POST', uri)
            ..fields.addAll(fields)
            ..files.add(
              http.MultipartFile(
                fieldName,
                uploadStream,
                totalBytes,
                // MVSEP expects uploaded filename to include an audio extension.
                filename: uploadFilename,
              ),
            );

          final streamedResponse = await client.send(request);
          onUploadProgress?.call(totalBytes, totalBytes);
          final body = await streamedResponse.stream.bytesToString();
          if (streamedResponse.statusCode < 200 ||
              streamedResponse.statusCode >= 300) {
            final bodyPreview = _previewText(body);
            lastError = StateError(
              'HTTP ${streamedResponse.statusCode} for ${uri.path} '
              'with field "$fieldName": body_preview=$bodyPreview',
            );
            continue;
          }

          try {
            return jsonDecode(body);
          } catch (_) {
            return body;
          }
        } catch (e) {
          lastError = e;
        }
      }

      throw StateError('Failed multipart upload for ${uri.path}: $lastError');
    } finally {
      client.close();
    }
  }

  Future<String> _buildUploadFilename(String filePath) async {
    final baseName = p.basename(filePath);
    final normalizedBaseName = baseName.trim().isEmpty ? 'audio' : baseName;
    if (p.extension(normalizedBaseName).isNotEmpty) {
      return normalizedBaseName;
    }

    final ext = await _detectAudioExtension(filePath);
    return '$normalizedBaseName$ext';
  }

  Future<String> _detectAudioExtension(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return '.mp3';
      }

      final builder = BytesBuilder(copy: false);
      await for (final chunk in file.openRead(0, 64)) {
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (bytes.isEmpty) {
        return '.mp3';
      }

      if (_startsWithAscii(bytes, 'ID3') || _looksLikeMp3FrameSync(bytes)) {
        return '.mp3';
      }
      if (_startsWithAscii(bytes, 'fLaC')) {
        return '.flac';
      }
      if (_startsWithAscii(bytes, 'OggS')) {
        return '.ogg';
      }
      if (_startsWithAscii(bytes, 'RIFF') &&
          _containsAsciiAt(bytes, 'WAVE', 8)) {
        return '.wav';
      }
      if (_containsAsciiAt(bytes, 'ftyp', 4)) {
        return '.m4a';
      }
      if (_startsWithBytes(bytes, const <int>[0x1A, 0x45, 0xDF, 0xA3])) {
        return '.webm';
      }
      if (_looksLikeAacAdts(bytes)) {
        return '.aac';
      }
    } catch (_) {
      // Fall through to default extension.
    }

    return '.mp3';
  }

  String _previewObjectForError(Object? value) {
    try {
      return _previewText(jsonEncode(value));
    } catch (_) {
      return _previewText(value?.toString() ?? '<null>');
    }
  }

  String _previewText(String input) {
    final sanitized = input.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      ' ',
    );
    final compact = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= _maxErrorPreviewChars) {
      return compact;
    }
    return '${compact.substring(0, _maxErrorPreviewChars)}...(truncated, ${compact.length} chars)';
  }

  bool _startsWithAscii(List<int> bytes, String text) {
    final chars = text.codeUnits;
    if (bytes.length < chars.length) {
      return false;
    }
    for (var i = 0; i < chars.length; i++) {
      if (bytes[i] != chars[i]) {
        return false;
      }
    }
    return true;
  }

  bool _containsAsciiAt(List<int> bytes, String text, int offset) {
    final chars = text.codeUnits;
    if (bytes.length < offset + chars.length) {
      return false;
    }
    for (var i = 0; i < chars.length; i++) {
      if (bytes[offset + i] != chars[i]) {
        return false;
      }
    }
    return true;
  }

  bool _startsWithBytes(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) {
      return false;
    }
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) {
        return false;
      }
    }
    return true;
  }

  bool _looksLikeMp3FrameSync(List<int> bytes) {
    if (bytes.length < 2) {
      return false;
    }
    final first = bytes[0];
    final second = bytes[1];
    return first == 0xFF && (second & 0xE0) == 0xE0;
  }

  bool _looksLikeAacAdts(List<int> bytes) {
    if (bytes.length < 2) {
      return false;
    }
    final first = bytes[0];
    final second = bytes[1];
    return first == 0xFF && (second & 0xF6) == 0xF0;
  }

  String? _extractHashFromAny(Object? value) {
    if (value == null) {
      return null;
    }

    final direct = _searchHashField(value);
    if (direct != null) {
      return direct;
    }

    final text = value is String ? value : jsonEncode(value);
    final match = RegExp(
      r'''(\d{14}-[a-z0-9]{8,}[^\s"']*\.(?:mp3|wav|flac|m4a|aac|ogg|opus|webm))''',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1);
  }

  String? _searchHashField(Object? value) {
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.key.toString().toLowerCase() == 'hash' &&
            entry.value is String) {
          return entry.value as String;
        }
        final nested = _searchHashField(entry.value);
        if (nested != null) {
          return nested;
        }
      }
    } else if (value is List) {
      for (final item in value) {
        final nested = _searchHashField(item);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }

  bool _isProcessingStatus(String status) {
    return status.contains('process') ||
        status.contains('run') ||
        status.contains('progress') ||
        status == 'working';
  }

  bool _isCompletedStatus(String status) {
    return status == 'done' ||
        status == 'success' ||
        status == 'finished' ||
        status == 'complete' ||
        status == 'completed';
  }

  bool _isFailedStatus(String status) {
    return status == 'failed' ||
        status == 'error' ||
        status == 'canceled' ||
        status == 'cancelled';
  }

  void _notifyQueuePositionChanged() {
    final indexedQueue = _localQueue.toList(growable: false);
    for (var i = 0; i < indexedQueue.length; i++) {
      final job = indexedQueue[i];
      for (final listener in job.listeners) {
        _emitToController(
          listener.stream,
          MvsepLocalQueuedEvent(
            audioPath: job.audioPath,
            localQueuePosition: i + 1,
            localQueueSize: indexedQueue.length,
            attachedToExistingTask: false,
          ),
        );
      }
    }
  }

  void _emitLocalPosition(_SeparationJob job) {
    final index = _localQueue.toList(growable: false).indexOf(job);
    final inQueue = index >= 0;
    final position = inQueue ? index + 1 : 0;

    _emitToJob(
      job,
      inQueue
          ? MvsepLocalQueuedEvent(
              audioPath: job.audioPath,
              localQueuePosition: position,
              localQueueSize: _localQueue.length,
              attachedToExistingTask: true,
            )
          : MvsepLocalRunningEvent(
              audioPath: job.audioPath,
              attachedToExistingTask: true,
            ),
    );
  }

  int? _extractIntByKeys(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      final parsed = _asInt(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  Future<int?> _safeFileSize(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  void _emitToJob(_SeparationJob job, MvsepTaskEvent event) {
    for (final listener in job.listeners) {
      _emitToController(listener.stream, event);
    }
  }

  void _emitToController(
    StreamController<MvsepTaskEvent> controller,
    MvsepTaskEvent event,
  ) {
    if (!controller.isClosed) {
      controller.add(event);
    }
  }

  Future<void> _closeJobListeners(_SeparationJob job) async {
    for (final listener in job.listeners) {
      if (!listener.stream.isClosed) {
        await listener.stream.close();
      }
    }
  }

  Future<void> _ensureStoreLoaded() async {
    if (_storeLoaded) {
      return;
    }

    final storeFile = await _storeFile();
    if (!await storeFile.exists()) {
      _storeLoaded = true;
      return;
    }

    try {
      final content = await storeFile.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        _storeLoaded = true;
        return;
      }

      final records = decoded['records'];
      if (records is! List) {
        _storeLoaded = true;
        return;
      }

      for (final item in records) {
        if (item is! Map) {
          continue;
        }
        final record = _TaskRecord.fromJson(
          item.cast<String, dynamic>(),
        ).sanitize();
        _records[record.audioPath] = record;
      }
    } catch (_) {
      // Corrupted cache should not block playback features.
    }

    _storeLoaded = true;
  }

  Future<void> _persistStore() async {
    final file = await _storeFile();
    await file.parent.create(recursive: true);

    final records = _records.values.map((record) => record.toJson()).toList();
    final payload = <String, dynamic>{'version': 1, 'records': records};
    await file.writeAsString(jsonEncode(payload));
  }

  Future<Directory> _mvsepBaseDir() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory(p.join(appDir.path, 'mvsep_service'));
  }

  Future<File> _storeFile() async {
    final base = await _mvsepBaseDir();
    return File(p.join(base.path, 'task_store.json'));
  }

  Future<void> _deleteFileIfExists(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _normalizePath(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return p.canonicalize(trimmed);
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String? _asString(Object? value) {
    if (value is String) {
      return value;
    }
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }
}

class _PollResult {
  const _PollResult({
    required this.status,
    required this.data,
    required this.raw,
  });

  final String status;
  final Map<String, dynamic> data;
  final Map<String, dynamic> raw;
}

class _SeparationJob {
  _SeparationJob({required this.audioPath, required this.listeners});

  final String audioPath;
  final List<_JobListener> listeners;
}

class _JobListener {
  const _JobListener({
    required this.stream,
    required this.saveVocalPath,
    required this.saveInstruPath,
  });

  final StreamController<MvsepTaskEvent> stream;
  final String saveVocalPath;
  final String saveInstruPath;
}

class _StemUrls {
  const _StemUrls({required this.vocalUrl, required this.instruUrl});

  final String? vocalUrl;
  final String? instruUrl;
}

class _NamedUrl {
  const _NamedUrl({required this.keyPath, required this.url});

  final String keyPath;
  final String url;
}

class _CachePaths {
  const _CachePaths({required this.vocalPath, required this.instruPath});

  final String vocalPath;
  final String instruPath;
}

enum _TaskRecordStatus {
  localQueued,
  localRunning,
  remoteWaiting,
  remoteProcessing,
  completed,
  failed,
}

class _TaskRecord {
  _TaskRecord({
    required this.audioPath,
    required this.status,
    required this.updatedAtMs,
    this.hash,
    this.algorithmId,
    this.algorithmName,
    this.vocalCachePath,
    this.instruCachePath,
    this.lastRemoteStatus,
    this.lastRemoteData,
    this.lastError,
  });

  factory _TaskRecord.empty({required String audioPath}) {
    return _TaskRecord(
      audioPath: audioPath,
      status: _TaskRecordStatus.localQueued,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory _TaskRecord.fromJson(Map<String, dynamic> json) {
    return _TaskRecord(
      audioPath: (json['audio_path'] ?? '').toString(),
      status: _parseStatus(json['status']?.toString()),
      updatedAtMs: (json['updated_at_ms'] as num?)?.toInt() ?? 0,
      hash: json['hash']?.toString(),
      algorithmId: (json['algorithm_id'] as num?)?.toInt(),
      algorithmName: json['algorithm_name']?.toString(),
      vocalCachePath: json['vocal_cache_path']?.toString(),
      instruCachePath: json['instru_cache_path']?.toString(),
      lastRemoteStatus: json['last_remote_status']?.toString(),
      lastRemoteData: (json['last_remote_data'] is Map)
          ? (json['last_remote_data'] as Map).cast<String, dynamic>()
          : null,
      lastError: json['last_error']?.toString(),
    );
  }

  final String audioPath;
  _TaskRecordStatus status;
  int updatedAtMs;
  String? hash;
  int? algorithmId;
  String? algorithmName;
  String? vocalCachePath;
  String? instruCachePath;
  String? lastRemoteStatus;
  Map<String, dynamic>? lastRemoteData;
  String? lastError;

  bool get isCompleted =>
      status == _TaskRecordStatus.completed &&
      vocalCachePath != null &&
      instruCachePath != null;

  void touch({required _TaskRecordStatus status}) {
    this.status = status;
    updatedAtMs = DateTime.now().millisecondsSinceEpoch;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'audio_path': audioPath,
      'status': status.name,
      'updated_at_ms': updatedAtMs,
      'hash': hash,
      'algorithm_id': algorithmId,
      'algorithm_name': algorithmName,
      'vocal_cache_path': vocalCachePath,
      'instru_cache_path': instruCachePath,
      'last_remote_status': lastRemoteStatus,
      'last_remote_data': lastRemoteData,
      'last_error': lastError,
    };
  }

  _TaskRecord sanitize() {
    if (audioPath.isEmpty) {
      return _TaskRecord.empty(audioPath: audioPath);
    }
    return this;
  }

  static _TaskRecordStatus _parseStatus(String? value) {
    return _TaskRecordStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => _TaskRecordStatus.localQueued,
    );
  }
}
