import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '/play_controller/play_controller.dart';

import 'waveform_controller.dart';
import 'waveform_math.dart';

class WaveformOverview extends StatefulWidget {
  const WaveformOverview({
    required this.playController,
    required this.waveformController,
    required this.fixedColor,
    required this.liveColor,
    required this.sliderColor,
    required this.sliderBorderColor,
    this.onPositionTap,
    this.height = 48.0,
    this.minWindowRatio = 0.04,
    super.key,
  });

  final PlayController playController;
  final WaveformController waveformController;
  final Color fixedColor;
  final Color liveColor;
  final Color sliderColor;
  final Color sliderBorderColor;
  final ValueChanged<Duration>? onPositionTap;
  final double height;
  final double minWindowRatio;

  @override
  State<WaveformOverview> createState() => _WaveformOverviewState();
}

class _WaveformOverviewState extends State<WaveformOverview> {
  static const double _scrollZoomSensitivity = 0.0015;

  List<double> _samples = const [];
  bool _isLoading = false;
  bool _primeScheduled = false;
  bool _hasTriedLoad = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _scheduleLoadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant WaveformOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playController != widget.playController) {
      _resetOverviewState();
      _scheduleLoadIfNeeded();
    }
  }

  void _scheduleLoadIfNeeded() {
    if (_primeScheduled || _hasTriedLoad || _isLoading || _samples.isNotEmpty) {
      return;
    }

    _primeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primeScheduled = false;
      if (!mounted || _hasTriedLoad || _isLoading || _samples.isNotEmpty) {
        return;
      }
      unawaited(_loadSamples());
    });
  }

  Future<void> _loadSamples() async {
    if (_hasTriedLoad) {
      return;
    }

    if (!widget.playController.isInitialized ||
        widget.playController.duration == Duration.zero) {
      return;
    }

    _hasTriedLoad = true;
    final token = ++_loadToken;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final totalSeconds = widget.playController.duration.inMilliseconds / 1000;
      final sampleCount = max(240, min(2400, (totalSeconds * 14).round()));

      final samples = await widget.playController.loadSamples(
        start: Duration.zero,
        end: widget.playController.duration,
        sampleCount: sampleCount,
      );

      if (!mounted || token != _loadToken) {
        return;
      }

      setState(() {
        _samples = samples;
      });
    } catch (_) {
      if (!mounted || token != _loadToken) {
        return;
      }

      setState(() {
        _samples = const [];
      });
    } finally {
      if (mounted && token == _loadToken) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetOverviewState() {
    _loadToken++;
    _primeScheduled = false;
    _hasTriedLoad = false;
    if (!mounted) {
      _samples = const [];
      _isLoading = false;
      return;
    }

    setState(() {
      _samples = const [];
      _isLoading = false;
    });
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }

    final nextScale =
        widget.waveformController.scale +
        event.scrollDelta.dy * _scrollZoomSensitivity;
    widget.waveformController.scale = nextScale;
  }

  void _updatePositionByLocalDx({
    required double localDx,
    required double width,
    required int totalMs,
  }) {
    if (width <= 0 || totalMs <= 0) {
      return;
    }

    final target = durationFromDistance(
      offset: localDx,
      total: width,
      totalMs: totalMs,
    );
    widget.waveformController.position = target;
    widget.onPositionTap?.call(target);
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLoadIfNeeded();

    return Listener(
      onPointerSignal: _onPointerSignal,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.playController.positionNotifier,
          widget.waveformController,
        ]),
        builder: (context, _) {
          final totalMs = safeTotalMilliseconds(widget.playController.duration);
          final positionRatio = ratioFromDuration(
            value: widget.waveformController.position,
            totalMs: totalMs,
          );
          final playedRatio = ratioFromDuration(
            value: widget.playController.positionNotifier.value,
            totalMs: totalMs,
          );
          final rawWindowRatio =
              widget.waveformController.window.inMilliseconds / totalMs;
          final windowRatio = rawWindowRatio
              .clamp(widget.minWindowRatio, 1.0)
              .toDouble();
          final leftRatio = (positionRatio - windowRatio / 2)
              .clamp(0.0, 1.0 - windowRatio)
              .toDouble();

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final sliderLeft = width * leftRatio;
              final sliderWidth = min(width - sliderLeft, width * windowRatio);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  _updatePositionByLocalDx(
                    localDx: details.localPosition.dx,
                    width: width,
                    totalMs: totalMs,
                  );
                },
                onHorizontalDragStart: (details) {
                  _updatePositionByLocalDx(
                    localDx: details.localPosition.dx,
                    width: width,
                    totalMs: totalMs,
                  );
                },
                onHorizontalDragUpdate: (details) {
                  _updatePositionByLocalDx(
                    localDx: details.localPosition.dx,
                    width: width,
                    totalMs: totalMs,
                  );
                },
                child: [
                  CustomPaint(
                    painter: _OverviewSamplesPainter(
                      samples: _samples,
                      playedRatio: playedRatio,
                      fixedColor: widget.fixedColor,
                      liveColor: widget.liveColor,
                    ),
                    child: const SizedBox.expand(),
                  ),
                  IgnorePointer(
                    child: Container(
                      width: sliderWidth,
                      decoration: BoxDecoration(
                        color: widget.sliderColor,
                        border: Border.all(color: widget.sliderBorderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ).positioned(left: sliderLeft, top: 0, bottom: 0),
                  if (_isLoading && _samples.isEmpty)
                    const CircularProgressIndicator(strokeWidth: 2).center(),
                ].toStack(),
              );
            },
          ).constrained(height: widget.height);
        },
      ),
    );
  }
}

class _OverviewSamplesPainter extends CustomPainter {
  const _OverviewSamplesPainter({
    required this.samples,
    required this.playedRatio,
    required this.fixedColor,
    required this.liveColor,
  });

  final List<double> samples;
  final double playedRatio;
  final Color fixedColor;
  final Color liveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final baselinePaint = Paint()
      ..color = fixedColor.withValues(alpha: 0.20)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      baselinePaint,
    );

    if (samples.isEmpty) {
      return;
    }

    final playedX = (size.width * playedRatio).clamp(0.0, size.width);
    final step = size.width / samples.length;
    final strokeWidth = max(1.0, step * 0.65);

    final fixedPaint = Paint()
      ..color = fixedColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final livePaint = Paint()
      ..color = liveColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (var i = 0; i < samples.length; i++) {
      final amplitude = toVisualAmplitude(samples[i]);
      if (amplitude <= 0) {
        continue;
      }

      final x = i * step + step / 2;
      final barHeight = max(strokeWidth, size.height * amplitude * 0.90);
      final top = (size.height - barHeight) / 2;
      final bottom = top + barHeight;
      final paint = x <= playedX ? livePaint : fixedPaint;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OverviewSamplesPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.playedRatio != playedRatio ||
        oldDelegate.fixedColor != fixedColor ||
        oldDelegate.liveColor != liveColor;
  }
}
