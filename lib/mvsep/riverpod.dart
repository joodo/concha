import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/network/network.dart';
import '/persistence/persistence.dart';
import '/projects/projects.dart';
import '/utils/utils.dart';

import 'models.dart';
import 'service.dart';

part 'riverpod.g.dart';

enum MvsepOperation { separation, transcription }

Duration? _separateJobCreatingRetry(int retryCount, Object error) {
  if (error is! MvsepMaxConcurrencyReachedException) return null;
  debugPrint('Mvsep max concurrency reached, retry after 2s...');
  return 2.seconds;
}

@Riverpod(retry: _separateJobCreatingRetry)
@JsonPersist()
class MvsepJobNotifier extends _$MvsepJobNotifier with LoadPersistOrFetch {
  @override
  Future<MvsepJob> build(String audioPath, MvsepOperation operation) {
    return loadPersistOrFetch(
      persist: persist(
        ref.watch(persistStorageProvider.future),
        options: const StorageOptions(
          cacheTime: StorageCacheTime.unsafe_forever,
        ),
      ),
      fetch: _fetch,
    );
  }

  Future<MvsepJob> _fetch() async {
    try {
      void onUploadProgress(int count, int total) {
        state = AsyncLoading(progress: (count / total).clamp(0.0, 1.0));
      }

      final job = await switch (operation) {
        .separation => MvsepService.i.createSeparationJob(
          audioPath,
          onUploadProgress: onUploadProgress,
        ),
        .transcription => MvsepService.i.createTranscriptionJob(
          audioPath,
          onUploadProgress: onUploadProgress,
        ),
      };
      return job;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _deleteStorage() async {
    final storage = await ref.read(persistStorageProvider.future);
    await storage.delete(key);
  }
}

Duration? _autoRecreateJobRetry(int retryCount, Object error) {
  if (error is! MvsepJobNotFound) return null;
  debugPrint('Mvsep job concurrency staled, retry');
  return Duration.zero;
}

@Riverpod(retry: _autoRecreateJobRetry)
class SeparationPath extends _$SeparationPath {
  @override
  Future<({String vocal, String instrument})> build(String id) async {
    // Check exist files
    final path = ProjectPath(id);
    final result = (vocal: path.audioVocals, instrument: path.audioInstru);

    if (await File(result.vocal).exists() &&
        await File(result.instrument).exists()) {
      return result;
    }

    // Fetch
    final link = ref.keepAlive();
    try {
      await _fetch();
      return result;
    } finally {
      link.close();
    }
  }

  Future<void> _fetch() async {
    final path = ProjectPath(id);
    final result = (vocal: path.audioVocals, instrument: path.audioInstru);

    // Create job
    final jobProvider = mvsepJobProvider(path.audio, .separation);
    ref.listen(jobProvider, (previous, next) {
      if (next is AsyncLoading && next.progress != null) {
        state = AsyncLoading(progress: 0.25 * next.progress!);
      }
    });

    final job = await ref.watch(jobProvider.future);

    // Wait job
    int? initOrder;
    late final MvsepResult jobResult;
    try {
      jobResult = await MvsepService.i.waitMvsepJob(
        job,
        onStatusChanged: (status) {
          switch (status) {
            case MvsepJobStatusWaiting(:final currentOrder):
              initOrder ??= currentOrder;
              double queueProgress = 1.0 - currentOrder / initOrder!;
              queueProgress = queueProgress.clamp(0.0, 1.0);
              state = AsyncLoading(progress: 0.25 + 0.25 * queueProgress);
            case MvsepJobStatusProcessing():
              state = AsyncLoading(progress: 0.25 * 2);
            case MvsepJobStatusDone():
              state = AsyncLoading(progress: 0.25 * 3);
          }
        },
      );
      if (jobResult is! MvsepSeparationResult) throw TypeError();
    } catch (e) {
      await ref.read(jobProvider.notifier)._deleteStorage();
      rethrow;
    }

    // Download files to temp dir
    final tempDir = await getTemporaryDirectory();
    final tempFiles = (
      vocal: p.join(tempDir.path, jobResult.vocalUrl.pathSegments.last),
      instrument: p.join(
        tempDir.path,
        jobResult.instrumentUrl.pathSegments.last,
      ),
    );

    ({int downloaded, int total})? vocalProgress, instruProgress;
    void updateProgressIfHas() {
      if (vocalProgress != null && instruProgress != null) {
        double progress =
            (vocalProgress!.downloaded + instruProgress!.downloaded) /
            (vocalProgress!.total + instruProgress!.total);
        progress = progress.clamp(0.0, 1.0);
        state = AsyncLoading(progress: 0.25 * 3 + 0.25 * progress);
      }
    }

    await Future.wait([
      http().downloadUri(
        jobResult.vocalUrl,
        tempFiles.vocal,
        onReceiveProgress: (count, total) {
          vocalProgress = (downloaded: count, total: total);
          updateProgressIfHas();
        },
      ),
      http().downloadUri(
        jobResult.instrumentUrl,
        tempFiles.instrument,
        onReceiveProgress: (count, total) {
          instruProgress = (downloaded: count, total: total);
          updateProgressIfHas();
        },
      ),
    ]);

    // Move file to project dir
    await File(tempFiles.vocal).rename(result.vocal);
    await File(tempFiles.instrument).rename(result.instrument);

    // Delete mvsep job cache
    await ref.read(jobProvider.notifier)._deleteStorage();
  }
}

@Riverpod(retry: _autoRecreateJobRetry)
class TranscribedLyric extends _$TranscribedLyric {
  @override
  Future<String> build(String id) async {
    final link = ref.keepAlive();
    try {
      return await _fetch();
    } finally {
      link.close();
    }
  }

  Future<String> _fetch() async {
    final vocalPath = ProjectPath(id).audioVocals;

    // Create job
    final jobProvider = mvsepJobProvider(vocalPath, .transcription);
    ref.listen(jobProvider, (previous, next) {
      if (next is AsyncLoading && next.progress != null) {
        state = AsyncLoading(progress: 0.33 * next.progress!);
      }
    });

    final job = await ref.watch(jobProvider.future);

    // Wait job
    int? initOrder;
    late final MvsepResult jobResult;
    try {
      jobResult = await MvsepService.i.waitMvsepJob(
        job,
        onStatusChanged: (status) {
          switch (status) {
            case MvsepJobStatusWaiting(:final currentOrder):
              initOrder ??= currentOrder;
              double queueProgress = 1.0 - currentOrder / initOrder!;
              queueProgress = queueProgress.clamp(0.0, 1.0);
              state = AsyncLoading(progress: 0.33 + 0.25 * queueProgress);
            case MvsepJobStatusProcessing():
              state = AsyncLoading(progress: 0.33 * 2);
            case MvsepJobStatusDone():
              state = AsyncLoading(progress: 0.33 * 3);
          }
        },
      );
      if (jobResult is! MvsepTranscriptionResult) throw TypeError();
    } finally {
      // Delete mvsep job cache
      await ref.read(jobProvider.notifier)._deleteStorage();
    }

    return jobResult.lrc;
  }
}
