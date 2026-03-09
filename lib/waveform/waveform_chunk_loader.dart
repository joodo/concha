import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import 'chunk_cache_state.dart';

class WaveformChunkLoader {
  WaveformChunkLoader({
    required this.chunkSeconds,
    required this.tickPixelSpan,
    required this.minSecondsPerTick,
  });

  final double chunkSeconds;
  final double tickPixelSpan;
  final double minSecondsPerTick;

  double _lastScrollOffset = 0.0;

  void resetScrollTracking() {
    _lastScrollOffset = 0.0;
  }

  Future<void> loadVisibleRange({
    required bool hasSource,
    required bool isInitialized,
    required Duration duration,
    required double viewportWidth,
    required bool hasScrollClients,
    required double scrollOffset,
    required double pixelsPerSecond,
    required ChunkCacheState cache,
    required bool mounted,
    required Future<List<double>> Function({
      required Duration start,
      required Duration end,
      required int sampleCount,
    })
    loadSamples,
    required VoidCallback onCacheChanged,
  }) async {
    if (!hasSource || !isInitialized) {
      return;
    }

    if (viewportWidth <= 0 || !hasScrollClients) {
      return;
    }

    final offset = scrollOffset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    final visibleStartSec = offset / pixelsPerSecond;
    final visibleEndSec = (offset + viewportWidth) / pixelsPerSecond;

    final totalSeconds = duration.inMilliseconds / 1000;
    final totalChunks = max(1, (totalSeconds / chunkSeconds).ceil());
    final startChunk = max(0, (visibleStartSec / chunkSeconds).floor());
    final endChunk = min(
      totalChunks - 1,
      (visibleEndSec / chunkSeconds).floor(),
    );

    final movingForward = delta >= 0;
    final fastScroll = delta.abs() > 80;
    final leadChunks = fastScroll ? 3 : 1;
    const tailChunks = 1;

    final rangeStart = max(
      0,
      startChunk - (movingForward ? tailChunks : leadChunks),
    );
    final rangeEnd = min(
      totalChunks - 1,
      endChunk + (movingForward ? leadChunks : tailChunks),
    );

    final generation = cache.generation;
    for (var chunk = rangeStart; chunk <= rangeEnd; chunk++) {
      unawaited(
        _loadChunk(
          chunkIndex: chunk,
          generation: generation,
          duration: duration,
          cache: cache,
          mounted: mounted,
          loadSamples: loadSamples,
          onCacheChanged: onCacheChanged,
        ),
      );
    }

    final visibleSpan = max(1, rangeEnd - rangeStart + 1);
    final adaptivePadding = max(4, min(24, (visibleSpan * 0.5).ceil()));
    final keepStart = max(0, rangeStart - adaptivePadding);
    final keepEnd = min(totalChunks - 1, rangeEnd + adaptivePadding);

    final removed = cache.evictOutside(keepStart, keepEnd);
    if (removed && mounted) {
      onCacheChanged();
    }
  }

  Future<void> _loadChunk({
    required int chunkIndex,
    required int generation,
    required Duration duration,
    required ChunkCacheState cache,
    required bool mounted,
    required Future<List<double>> Function({
      required Duration start,
      required Duration end,
      required int sampleCount,
    })
    loadSamples,
    required VoidCallback onCacheChanged,
  }) async {
    if (cache.isLoading(chunkIndex) || cache.hasChunk(chunkIndex)) {
      return;
    }

    cache.markLoading(chunkIndex);
    try {
      final startSec = chunkIndex * chunkSeconds;
      final totalSeconds = duration.inMilliseconds / 1000;
      final endSec = min(totalSeconds, startSec + chunkSeconds);

      if (endSec <= startSec) {
        return;
      }

      final basePixelsPerSecond = tickPixelSpan / minSecondsPerTick;
      final barsPerSecond = max(8, (basePixelsPerSecond / 2.2).round());
      final sampleCount = max(
        64,
        min(1200, ((endSec - startSec) * barsPerSecond).ceil()),
      );

      final samples = await loadSamples(
        start: Duration(milliseconds: (startSec * 1000).round()),
        end: Duration(milliseconds: (endSec * 1000).round()),
        sampleCount: sampleCount,
      );

      if (!mounted || generation != cache.generation) {
        return;
      }

      cache.store(chunkIndex, samples);
      onCacheChanged();
    } finally {
      cache.unmarkLoading(chunkIndex);
    }
  }
}
