import 'dart:math';

class ProgressLineLockState {
  ProgressLineLockState({
    this.centerLockTolerance = 1.5,
    this.edgeUnlockPadding = 3.0,
  });

  final double centerLockTolerance;
  final double edgeUnlockPadding;

  bool _isCenterLocked = false;

  void reset() {
    _isCenterLocked = false;
  }

  double resolveViewportX({
    required bool isBound,
    required double progressContentX,
    required double scrollOffset,
    required double viewportWidth,
    required double contentWidth,
  }) {
    final rawProgressViewportX = (progressContentX - scrollOffset)
        .clamp(0.0, viewportWidth)
        .toDouble();
    final centerX = viewportWidth / 2;

    final maxOffset = max(0.0, contentWidth - viewportWidth);
    final atScrollBoundary =
        scrollOffset <= edgeUnlockPadding ||
        scrollOffset >= maxOffset - edgeUnlockPadding;
    final canKeepCentered =
        progressContentX >= centerX &&
        progressContentX <= contentWidth - centerX;

    if (!isBound || atScrollBoundary || !canKeepCentered) {
      _isCenterLocked = false;
    } else if (!_isCenterLocked &&
        (rawProgressViewportX - centerX).abs() <= centerLockTolerance) {
      _isCenterLocked = true;
    }

    return _isCenterLocked ? centerX : rawProgressViewportX;
  }
}
