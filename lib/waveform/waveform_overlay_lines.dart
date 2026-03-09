import 'package:flutter/material.dart';

class WaveformOverlayLines extends StatelessWidget {
  const WaveformOverlayLines({
    required this.startLineColor,
    required this.hoverLineColor,
    required this.progressLineColor,
    this.startLineX,
    this.hoverLineX,
    this.progressLineX,
    this.startLineStrokeWidth = 2.2,
    this.hoverLineStrokeWidth = 1.5,
    this.progressLineStrokeWidth = 1.5,
    super.key,
  });

  final double? startLineX;
  final double? hoverLineX;
  final double? progressLineX;
  final Color startLineColor;
  final Color hoverLineColor;
  final Color progressLineColor;
  final double startLineStrokeWidth;
  final double hoverLineStrokeWidth;
  final double progressLineStrokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformOverlayLinesPainter(
        startLineX: startLineX,
        hoverLineX: hoverLineX,
        progressLineX: progressLineX,
        startLineColor: startLineColor,
        hoverLineColor: hoverLineColor,
        progressLineColor: progressLineColor,
        startLineStrokeWidth: startLineStrokeWidth,
        hoverLineStrokeWidth: hoverLineStrokeWidth,
        progressLineStrokeWidth: progressLineStrokeWidth,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _WaveformOverlayLinesPainter extends CustomPainter {
  const _WaveformOverlayLinesPainter({
    required this.startLineX,
    required this.hoverLineX,
    required this.progressLineX,
    required this.startLineColor,
    required this.hoverLineColor,
    required this.progressLineColor,
    required this.startLineStrokeWidth,
    required this.hoverLineStrokeWidth,
    required this.progressLineStrokeWidth,
  });

  final double? startLineX;
  final double? hoverLineX;
  final double? progressLineX;
  final Color startLineColor;
  final Color hoverLineColor;
  final Color progressLineColor;
  final double startLineStrokeWidth;
  final double hoverLineStrokeWidth;
  final double progressLineStrokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    _drawLine(
      canvas: canvas,
      size: size,
      x: startLineX,
      color: startLineColor,
      strokeWidth: startLineStrokeWidth,
    );
    _drawLine(
      canvas: canvas,
      size: size,
      x: hoverLineX,
      color: hoverLineColor,
      strokeWidth: hoverLineStrokeWidth,
    );
    _drawLine(
      canvas: canvas,
      size: size,
      x: progressLineX,
      color: progressLineColor,
      strokeWidth: progressLineStrokeWidth,
    );
  }

  void _drawLine({
    required Canvas canvas,
    required Size size,
    required double? x,
    required Color color,
    required double strokeWidth,
  }) {
    if (x == null) {
      return;
    }

    final clampedX = x.clamp(0.0, size.width).toDouble();
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    canvas.drawLine(Offset(clampedX, 0), Offset(clampedX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _WaveformOverlayLinesPainter oldDelegate) {
    return oldDelegate.startLineX != startLineX ||
        oldDelegate.hoverLineX != hoverLineX ||
        oldDelegate.progressLineX != progressLineX ||
        oldDelegate.startLineColor != startLineColor ||
        oldDelegate.hoverLineColor != hoverLineColor ||
        oldDelegate.progressLineColor != progressLineColor ||
        oldDelegate.startLineStrokeWidth != startLineStrokeWidth ||
        oldDelegate.hoverLineStrokeWidth != hoverLineStrokeWidth ||
        oldDelegate.progressLineStrokeWidth != progressLineStrokeWidth;
  }
}
