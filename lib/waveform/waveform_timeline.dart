import 'dart:math';

import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

class WaveformTimeline extends StatelessWidget {
  const WaveformTimeline({
    required this.duration,
    required this.pixelsPerSecond,
    required this.secondsPerTick,
    required this.color,
    required this.height,
    required this.onTapLocalDx,
    this.textStyle,
    this.onHoverLocalDx,
    this.onHoverExit,
    super.key,
  });

  final Duration duration;
  final double pixelsPerSecond;
  final double secondsPerTick;
  final Color color;
  final TextStyle? textStyle;
  final double height;
  final ValueChanged<double> onTapLocalDx;
  final ValueChanged<double>? onHoverLocalDx;
  final VoidCallback? onHoverExit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => onTapLocalDx(details.localPosition.dx),
      child: MouseRegion(
        cursor: SystemMouseCursors.precise,
        onHover: onHoverLocalDx == null
            ? null
            : (event) => onHoverLocalDx!(event.localPosition.dx),
        onExit: onHoverExit == null ? null : (_) => onHoverExit!(),
        child: CustomPaint(
          painter: TimelinePainter(
            duration: duration,
            pixelsPerSecond: pixelsPerSecond,
            secondsPerTick: secondsPerTick,
            color: color,
            textStyle: textStyle,
          ),
          child: const SizedBox.expand(),
        ).constrained(height: height),
      ),
    );
  }
}

class TimelinePainter extends CustomPainter {
  const TimelinePainter({
    required this.duration,
    required this.pixelsPerSecond,
    required this.secondsPerTick,
    required this.color,
    this.textStyle,
  });

  final Duration duration;
  final double pixelsPerSecond;
  final double secondsPerTick;
  final Color color;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero || size.width <= 0 || size.height <= 0) {
      return;
    }

    final totalSeconds = duration.inMilliseconds / 1000;
    final tickSeconds = max(0.05, secondsPerTick);
    final totalTicks = (totalSeconds / tickSeconds).ceil();
    final labelEvery = max(1, (70 / (tickSeconds * pixelsPerSecond)).ceil());

    final basePaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    final majorPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      basePaint,
    );

    for (var tick = 0; tick <= totalTicks; tick++) {
      final second = tick * tickSeconds;
      final x = second * pixelsPerSecond;
      if (x > size.width) {
        break;
      }

      canvas.drawLine(
        Offset(x, size.height - 1),
        Offset(x, size.height - (tick % labelEvery == 0 ? 12 : 7)),
        tick % labelEvery == 0 ? majorPaint : basePaint,
      );

      if (tick % labelEvery != 0) {
        continue;
      }

      final label = _formatTime(second);
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final dx = (x - textPainter.width / 2).clamp(
        0.0,
        size.width - textPainter.width,
      );
      textPainter.paint(canvas, Offset(dx, 0));
    }
  }

  String _formatTime(double secondsValue) {
    final duration = Duration(milliseconds: (secondsValue * 1000).round());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (secondsPerTick < 1) {
      final decisecond = (duration.inMilliseconds % 1000) ~/ 100;
      return '$minutes:$seconds.$decisecond';
    }
    return '$minutes:$seconds';
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.duration != duration ||
        oldDelegate.pixelsPerSecond != pixelsPerSecond ||
        oldDelegate.secondsPerTick != secondsPerTick ||
        oldDelegate.color != color ||
        oldDelegate.textStyle != textStyle;
  }
}
