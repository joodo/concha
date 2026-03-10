import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '../play_controller.dart';
import 'chunk_cache_state.dart';
import 'playback_binding_state.dart';
import 'progress_line_lock_state.dart';
import 'waveform_controller.dart';
import 'waveform_chunk_loader.dart';
import 'waveform_math.dart';
import 'waveform_overlay_lines.dart';
import 'waveform_overview.dart';
import 'waveform_timeline.dart';

class Waveform extends StatefulWidget {
  const Waveform({
    required this.playController,
    required this.waveformController,
    super.key,
  });

  final PlayController playController;
  final WavefromController waveformController;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> {
  static const double _tickPixelSpan = 72.0;
  static const double _timelineHeight = 30.0;
  static const double _chunkSeconds = 12.0;

  final ScrollController _waveScrollController = ScrollController();
  double _waveformViewportWidth = 0.0;

  int _lastPositionMs = -1;
  bool _primeScheduled = false;
  bool _metricsUpdateScheduled = false;
  Duration _pendingPosition = Duration.zero;
  Duration _pendingWindow = Duration.zero;
  double _lastObservedScale = 1.0;
  bool _ignoreNextWaveScrollPositionSync = false;
  double? _hoverContentDx;
  bool _isHoverOnTimeline = false;

  final ChunkCacheState _chunkCache = ChunkCacheState();
  final PlaybackBindingState _playbackBinding = PlaybackBindingState();
  final ProgressLineLockState _progressLineLock = ProgressLineLockState();
  late final WaveformChunkLoader _chunkLoader = WaveformChunkLoader(
    chunkSeconds: _chunkSeconds,
    tickPixelSpan: _tickPixelSpan,
    minSecondsPerTick: WavefromController.minSecondsPerTick,
  );

  double get _secondsPerTick => widget.waveformController.scale;
  double get _pixelsPerSecond => _tickPixelSpan / _secondsPerTick;

  @override
  void initState() {
    super.initState();
    _lastObservedScale = widget.waveformController.scale;
    _playbackBinding.reset(widget.playController.isPlaying);
    widget.playController.addListener(_onPlayControllerChanged);
    widget.waveformController.addListener(_onWaveformControllerChanged);
    _waveScrollController.addListener(_onWaveScroll);
    _schedulePrimeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playController != widget.playController) {
      oldWidget.playController.removeListener(_onPlayControllerChanged);
      widget.playController.addListener(_onPlayControllerChanged);
      _progressLineLock.reset();
      _playbackBinding.reset(widget.playController.isPlaying);
      _resetCache();
      _schedulePrimeIfNeeded();
    }
    if (oldWidget.waveformController != widget.waveformController) {
      oldWidget.waveformController.removeListener(_onWaveformControllerChanged);
      widget.waveformController.addListener(_onWaveformControllerChanged);
      _lastObservedScale = widget.waveformController.scale;
    }
  }

  @override
  void dispose() {
    widget.playController.removeListener(_onPlayControllerChanged);
    widget.waveformController.removeListener(_onWaveformControllerChanged);
    _waveScrollController.removeListener(_onWaveScroll);
    _waveScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.playController.hasSource ||
        widget.playController.duration == Duration.zero) {
      return const SizedBox.expand();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return [
      WaveformOverview(
        playController: widget.playController,
        waveformController: widget.waveformController,
        onPositionTap: _onOverviewPositionTap,
        fixedColor: colorScheme.outline,
        liveColor: colorScheme.tertiary,
        sliderColor: colorScheme.tertiary.withValues(alpha: 0.20),
        sliderBorderColor: colorScheme.tertiary.withValues(alpha: 0.50),
      ).backgroundColor(colorScheme.surfaceContainerLow),
      LayoutBuilder(
        builder: (context, waveConstraints) {
          if ((_waveformViewportWidth - waveConstraints.maxWidth).abs() > 0.5) {
            _waveformViewportWidth = waveConstraints.maxWidth;
            _progressLineLock.reset();
            _scheduleMetricsUpdate(
              position: _positionForMetrics(),
              window: _windowForViewportWidth(waveConstraints.maxWidth),
            );
          }

          final contentWidth = _contentWidthForViewport(
            waveConstraints.maxWidth,
          );

          return MouseRegion(
            onExit: (_) => _clearHoverLine(),
            child: [
              SingleChildScrollView(
                controller: _waveScrollController,
                scrollDirection: Axis.horizontal,
                child:
                    [
                      WaveformTimeline(
                        duration: widget.playController.duration,
                        pixelsPerSecond: _pixelsPerSecond,
                        secondsPerTick: _secondsPerTick,
                        height: _timelineHeight,
                        color: colorScheme.onSurfaceVariant,
                        textStyle: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                        onTapLocalDx: (localDx) {
                          _onTimelineTap(
                            localDx: localDx,
                            contentWidth: contentWidth,
                          );
                        },
                        onHoverLocalDx: (localDx) {
                          _onContentHover(
                            localDx: localDx,
                            contentWidth: contentWidth,
                            onTimeline: true,
                          );
                        },
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final target = _durationForContentDx(
                            localDx: details.localPosition.dx,
                            contentWidth: contentWidth,
                          );
                          unawaited(_seekTo(target));
                        },
                        child: Listener(
                          onPointerSignal: (event) {
                            _onWaveformPointerSignal(
                              event: event,
                              contentWidth: contentWidth,
                            );
                          },
                          child: MouseRegion(
                            onHover: (event) {
                              _onContentHover(
                                localDx: event.localPosition.dx,
                                contentWidth: contentWidth,
                                onTimeline: false,
                              );
                            },
                            child: ListenableBuilder(
                              listenable: Listenable.merge([
                                widget.playController,
                                _waveScrollController,
                              ]),
                              builder: (context, _) {
                                final progressX =
                                    contentWidth *
                                    ratioFromDuration(
                                      value: widget.playController.position,
                                      totalMs: safeTotalMilliseconds(
                                        widget.playController.duration,
                                      ),
                                    );
                                final scrollOffset =
                                    _waveScrollController.hasClients
                                    ? _waveScrollController.offset
                                    : 0.0;
                                final visibleStartX = max(
                                  0.0,
                                  scrollOffset - 24.0,
                                );
                                final visibleEndX = min(
                                  contentWidth,
                                  scrollOffset +
                                      waveConstraints.maxWidth +
                                      24.0,
                                );

                                return CustomPaint(
                                  painter: _WaveformPainter(
                                    chunkSampleCache: _chunkCache.chunks,
                                    sampleCacheRevision: _chunkCache.revision,
                                    chunkSeconds: _chunkSeconds,
                                    duration: widget.playController.duration,
                                    pixelsPerSecond: _pixelsPerSecond,
                                    progressX: progressX,
                                    visibleStartX: visibleStartX,
                                    visibleEndX: visibleEndX,
                                    fixedColor: colorScheme.outline,
                                    liveColor: colorScheme.primary,
                                  ),
                                  child: const SizedBox.expand(),
                                );
                              },
                            ),
                          ),
                        ),
                      ).expanded(),
                    ].toColumn().constrained(
                      width: contentWidth,
                      height: waveConstraints.maxHeight,
                    ),
              ),
              IgnorePointer(
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    widget.playController,
                    _waveScrollController,
                  ]),
                  builder: (context, _) {
                    final scrollOffset = _waveScrollController.hasClients
                        ? _waveScrollController.offset
                        : 0.0;
                    final startContentX =
                        contentWidth *
                        ratioFromDuration(
                          value: widget.playController.startPosition,
                          totalMs: safeTotalMilliseconds(
                            widget.playController.duration,
                          ),
                        );
                    final startViewportX = _visibleViewportX(
                      contentX: startContentX,
                      scrollOffset: scrollOffset,
                      viewportWidth: waveConstraints.maxWidth,
                    );

                    final hoverViewportX = _hoverContentDx == null
                        ? null
                        : _clampedViewportX(
                            contentX: _hoverContentDx!,
                            scrollOffset: scrollOffset,
                            viewportWidth: waveConstraints.maxWidth,
                          );

                    final progressContentX =
                        contentWidth *
                        ratioFromDuration(
                          value: widget.playController.position,
                          totalMs: safeTotalMilliseconds(
                            widget.playController.duration,
                          ),
                        );
                    final progressViewportX = _resolveProgressViewportX(
                      isBound: _playbackBinding.isBound,
                      progressContentX: progressContentX,
                      scrollOffset: scrollOffset,
                      viewportWidth: waveConstraints.maxWidth,
                      contentWidth: contentWidth,
                    );

                    return WaveformOverlayLines(
                      startLineX: startViewportX,
                      hoverLineX: hoverViewportX,
                      progressLineX: progressViewportX,
                      startLineColor: colorScheme.error,
                      hoverLineColor: _isHoverOnTimeline
                          ? colorScheme.error
                          : colorScheme.tertiary,
                      progressLineColor: colorScheme.primary,
                    );
                  },
                ),
              ),
            ].toStack(),
          );
        },
      ).expanded(),
    ].toColumn(separator: const SizedBox(height: 12));
  }

  void _onTimelineTap({required double localDx, required double contentWidth}) {
    widget.playController.startPosition = _durationForContentDx(
      localDx: localDx,
      contentWidth: contentWidth,
    );
  }

  void _onContentHover({
    required double localDx,
    required double contentWidth,
    required bool onTimeline,
  }) {
    final clampedDx = localDx.clamp(0.0, contentWidth).toDouble();
    final hoverMoved =
        _hoverContentDx == null || (clampedDx - _hoverContentDx!).abs() > 0.1;
    if (!hoverMoved && _isHoverOnTimeline == onTimeline) {
      return;
    }

    setState(() {
      _hoverContentDx = clampedDx;
      _isHoverOnTimeline = onTimeline;
    });
  }

  void _clearHoverLine() {
    if (_hoverContentDx == null && !_isHoverOnTimeline) {
      return;
    }

    setState(() {
      _hoverContentDx = null;
      _isHoverOnTimeline = false;
    });
  }

  double _resolveProgressViewportX({
    required bool isBound,
    required double progressContentX,
    required double scrollOffset,
    required double viewportWidth,
    required double contentWidth,
  }) {
    return _progressLineLock.resolveViewportX(
      isBound: isBound,
      progressContentX: progressContentX,
      scrollOffset: scrollOffset,
      viewportWidth: viewportWidth,
      contentWidth: contentWidth,
    );
  }

  double? _visibleViewportX({
    required double contentX,
    required double scrollOffset,
    required double viewportWidth,
  }) {
    final viewportEnd = scrollOffset + viewportWidth;
    final isVisible = contentX >= scrollOffset && contentX <= viewportEnd;
    if (!isVisible) {
      return null;
    }

    return contentX - scrollOffset;
  }

  double _clampedViewportX({
    required double contentX,
    required double scrollOffset,
    required double viewportWidth,
  }) {
    return (contentX - scrollOffset).clamp(0.0, viewportWidth).toDouble();
  }

  void _onWaveformPointerSignal({
    required PointerSignalEvent event,
    required double contentWidth,
  }) {
    if (event is! PointerScrollEvent) {
      return;
    }
    if (!_waveScrollController.hasClients) {
      return;
    }

    final maxOffset = max(0.0, contentWidth - _waveformViewportWidth);
    if (maxOffset <= 0) {
      return;
    }

    final scrollDelta = event.scrollDelta.dy.abs() >= event.scrollDelta.dx.abs()
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    if (scrollDelta == 0) {
      return;
    }

    _playbackBinding.detach(widget.playController.isPlaying);
    _progressLineLock.reset();

    final currentOffset = _waveScrollController.offset;
    final targetOffset = (currentOffset + scrollDelta).clamp(0.0, maxOffset);
    if ((targetOffset - currentOffset).abs() < 0.5) {
      return;
    }

    _waveScrollController.jumpTo(targetOffset);
  }

  Future<void> _seekTo(Duration target) async {
    _progressLineLock.reset();
    await widget.playController.seekTo(target);
    _syncScrollToProgress();
    unawaited(_loadChunksForVisibleRange());
  }

  void _onPlayControllerChanged() {
    final position = widget.playController.position;
    _playbackBinding.handlePlayState(widget.playController.isPlaying);
    if (_playbackBinding.isBound) {
      _scheduleFollowAndPreload(position.inMilliseconds);
    }
    _schedulePrimeIfNeeded();
    _scheduleMetricsUpdate(
      position: _playbackBinding.isBound
          ? position
          : widget.waveformController.position,
      window: _windowForViewportWidth(_waveformViewportWidth),
    );
  }

  void _scheduleFollowAndPreload(int positionMs) {
    if (positionMs == _lastPositionMs) {
      return;
    }
    _lastPositionMs = positionMs;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncScrollToProgress();
      unawaited(_loadChunksForVisibleRange());
    });
  }

  void _schedulePrimeIfNeeded() {
    if (_primeScheduled || !_chunkCache.isEmpty) {
      return;
    }
    _primeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _primeScheduled = false;
      if (_chunkCache.isEmpty) {
        unawaited(_loadChunksForVisibleRange());
      }
    });
  }

  void _onWaveformControllerChanged() {
    final scale = widget.waveformController.scale;
    if ((scale - _lastObservedScale).abs() < 0.0001) {
      return;
    }

    _lastObservedScale = scale;
    _scheduleMetricsUpdate(
      position: _positionForScaleChange(),
      window: _windowForViewportWidth(_waveformViewportWidth),
    );
    if (mounted) {
      setState(() {});
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _ignoreNextWaveScrollPositionSync = true;
      if (_playbackBinding.isBound) {
        _syncScrollToProgress();
      } else {
        _syncScrollToWaveformPosition(widget.waveformController.position);
      }
      unawaited(_loadChunksForVisibleRange());
    });
  }

  void _onOverviewPositionTap(Duration target) {
    _playbackBinding.detach(widget.playController.isPlaying);
    _progressLineLock.reset();

    _syncScrollToWaveformPosition(target);
    _scheduleMetricsUpdate(
      position: target,
      window: _windowForViewportWidth(_waveformViewportWidth),
    );
    unawaited(_loadChunksForVisibleRange());
  }

  Duration _positionForMetrics() {
    if (_playbackBinding.isBound) {
      return widget.playController.position;
    }
    return _positionForCurrentViewport();
  }

  Duration _positionForScaleChange() {
    if (_playbackBinding.isBound) {
      return widget.playController.position;
    }
    return widget.waveformController.position;
  }

  Duration _positionForCurrentViewport() {
    if (!_waveScrollController.hasClients || _waveformViewportWidth <= 0) {
      return widget.waveformController.position;
    }

    final contentWidth = _contentWidthForViewport(_waveformViewportWidth);
    if (contentWidth <= 0 || widget.playController.duration == Duration.zero) {
      return Duration.zero;
    }

    final centerX = (_waveScrollController.offset + _waveformViewportWidth / 2)
        .clamp(0.0, contentWidth)
        .toDouble();
    return durationFromRatio(
      ratio: ratioFromDistance(offset: centerX, total: contentWidth),
      totalMs: safeTotalMilliseconds(widget.playController.duration),
    );
  }

  double _contentWidthForViewport(double viewportWidth) {
    if (viewportWidth <= 0) {
      return 0;
    }
    final totalSeconds = widget.playController.duration.inMilliseconds / 1000;
    final contentWidth = totalSeconds * _pixelsPerSecond;
    return max(viewportWidth, contentWidth);
  }

  Duration _windowForViewportWidth(double viewportWidth) {
    if (viewportWidth <= 0 || _pixelsPerSecond <= 0) {
      return Duration.zero;
    }
    final milliseconds = max(
      0,
      ((viewportWidth / _pixelsPerSecond) * 1000).round(),
    );
    return Duration(milliseconds: milliseconds);
  }

  void _scheduleMetricsUpdate({
    required Duration position,
    required Duration window,
  }) {
    _pendingPosition = position;
    _pendingWindow = window;
    if (_metricsUpdateScheduled) {
      return;
    }

    _metricsUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metricsUpdateScheduled = false;
      if (!mounted) {
        return;
      }

      widget.waveformController.position = _pendingPosition;
      widget.waveformController.window = _pendingWindow;
    });
  }

  void _syncScrollToProgress() {
    if (!_playbackBinding.isBound) {
      return;
    }

    _jumpToOffsetForPosition(widget.playController.position);
  }

  void _syncScrollToWaveformPosition(Duration position) {
    _jumpToOffsetForPosition(position);
  }

  void _jumpToOffsetForPosition(Duration position) {
    final targetOffset = _targetOffsetForPosition(position);
    if (targetOffset == null) {
      return;
    }

    if ((_waveScrollController.offset - targetOffset).abs() < 0.5) {
      return;
    }

    _waveScrollController.jumpTo(targetOffset);
  }

  double? _targetOffsetForPosition(Duration position) {
    if (!_waveScrollController.hasClients || _waveformViewportWidth <= 0) {
      return null;
    }

    final contentWidth = _contentWidthForViewport(_waveformViewportWidth);
    final maxOffset = max(0.0, contentWidth - _waveformViewportWidth);
    final progress = ratioFromDuration(
      value: position,
      totalMs: safeTotalMilliseconds(widget.playController.duration),
    );
    return (contentWidth * progress - _waveformViewportWidth / 2).clamp(
      0.0,
      maxOffset,
    );
  }

  void _onWaveScroll() {
    if (_ignoreNextWaveScrollPositionSync) {
      _ignoreNextWaveScrollPositionSync = false;
      _scheduleMetricsUpdate(
        position: _positionForScaleChange(),
        window: _windowForViewportWidth(_waveformViewportWidth),
      );
      unawaited(_loadChunksForVisibleRange());
      return;
    }

    _scheduleMetricsUpdate(
      position: _positionForMetrics(),
      window: _windowForViewportWidth(_waveformViewportWidth),
    );
    unawaited(_loadChunksForVisibleRange());
  }

  Duration _durationForContentDx({
    required double localDx,
    required double contentWidth,
  }) {
    final clampedLocalDx = localDx.clamp(0.0, contentWidth).toDouble();

    return durationFromDistance(
      offset: clampedLocalDx,
      total: contentWidth,
      totalMs: safeTotalMilliseconds(widget.playController.duration),
    );
  }

  Future<void> _loadChunksForVisibleRange() async {
    await _chunkLoader.loadVisibleRange(
      hasSource: widget.playController.hasSource,
      isInitialized: widget.playController.isInitialized,
      duration: widget.playController.duration,
      viewportWidth: _waveformViewportWidth,
      hasScrollClients: _waveScrollController.hasClients,
      scrollOffset: _waveScrollController.hasClients
          ? _waveScrollController.offset
          : 0.0,
      pixelsPerSecond: _pixelsPerSecond,
      cache: _chunkCache,
      mounted: mounted,
      loadSamples: ({required start, required end, required sampleCount}) {
        return widget.playController.loadSamples(
          start: start,
          end: end,
          sampleCount: sampleCount,
        );
      },
      onCacheChanged: () {
        if (!mounted) {
          return;
        }
        setState(() {});
      },
    );
  }

  void _resetCache() {
    _chunkCache.reset();
    _chunkLoader.resetScrollTracking();
    _lastPositionMs = -1;
    if (mounted) {
      setState(() {});
    }
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.chunkSampleCache,
    required this.sampleCacheRevision,
    required this.chunkSeconds,
    required this.duration,
    required this.pixelsPerSecond,
    required this.progressX,
    required this.visibleStartX,
    required this.visibleEndX,
    required this.fixedColor,
    required this.liveColor,
  });

  final Map<int, List<double>> chunkSampleCache;
  final int sampleCacheRevision;
  final double chunkSeconds;
  final Duration duration;
  final double pixelsPerSecond;
  final double progressX;
  final double visibleStartX;
  final double visibleEndX;
  final Color fixedColor;
  final Color liveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final baselinePaint = Paint()
      ..color = fixedColor.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      baselinePaint,
    );

    if (chunkSampleCache.isEmpty || duration == Duration.zero) {
      return;
    }

    final totalSeconds = duration.inMilliseconds / 1000;

    final fixedPaint = Paint()
      ..color = fixedColor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final livePaint = Paint()
      ..color = liveColor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final chunkKeys = chunkSampleCache.keys.toList()..sort();
    for (final chunkIndex in chunkKeys) {
      final samples = chunkSampleCache[chunkIndex]!;
      if (samples.isEmpty) {
        continue;
      }

      final chunkStartSec = chunkIndex * chunkSeconds;
      if (chunkStartSec >= totalSeconds) {
        continue;
      }
      final chunkEndSec = min(totalSeconds, chunkStartSec + chunkSeconds);
      final chunkWidth = (chunkEndSec - chunkStartSec) * pixelsPerSecond;
      if (chunkWidth <= 0) {
        continue;
      }

      final chunkStartX = chunkStartSec * pixelsPerSecond;
      final chunkEndX = chunkStartX + chunkWidth;
      if (chunkEndX < visibleStartX || chunkStartX > visibleEndX) {
        continue;
      }

      final step = max(1.0, chunkWidth / samples.length);
      final strokeWidth = max(1.0, step * 0.6);
      fixedPaint.strokeWidth = strokeWidth;
      livePaint.strokeWidth = strokeWidth;

      final columns = max(1, min(samples.length, chunkWidth.ceil()));
      final columnWidth = chunkWidth / columns;
      final samplesPerColumn = samples.length / columns;

      for (var column = 0; column < columns; column++) {
        final from = (column * samplesPerColumn).floor();
        final to = min(
          samples.length,
          ((column + 1) * samplesPerColumn).ceil(),
        );
        if (to <= from) {
          continue;
        }

        var peak = 0.0;
        for (var i = from; i < to; i++) {
          final v = samples[i].abs();
          if (v > peak) {
            peak = v;
          }
        }

        final visualAmplitude = toVisualAmplitude(peak);
        if (visualAmplitude <= 0) {
          continue;
        }

        final barHeight = max(
          strokeWidth,
          visualAmplitude * size.height * 0.92,
        );
        final x = chunkStartX + (column + 0.5) * columnWidth;
        final top = (size.height - barHeight) / 2;
        final bottom = top + barHeight;
        final paint = x <= progressX ? livePaint : fixedPaint;
        canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.sampleCacheRevision != sampleCacheRevision ||
        oldDelegate.chunkSeconds != chunkSeconds ||
        oldDelegate.duration != duration ||
        oldDelegate.pixelsPerSecond != pixelsPerSecond ||
        oldDelegate.progressX != progressX ||
        oldDelegate.visibleStartX != visibleStartX ||
        oldDelegate.visibleEndX != visibleEndX ||
        oldDelegate.fixedColor != fixedColor ||
        oldDelegate.liveColor != liveColor;
  }
}
