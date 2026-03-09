import 'dart:math';

const double _noiseGate = 0.015;
const double _inputGain = 2.2;
const double _shapeExponent = 1.1;

int safeTotalMilliseconds(Duration duration) {
  return max(1, duration.inMilliseconds);
}

double clampUnit(double value) {
  return value.clamp(0.0, 1.0).toDouble();
}

double ratioFromDuration({required Duration value, required int totalMs}) {
  return clampUnit(value.inMilliseconds / max(1, totalMs));
}

double ratioFromDistance({required double offset, required double total}) {
  if (total <= 0) {
    return 0.0;
  }
  return clampUnit(offset / total);
}

Duration durationFromRatio({required double ratio, required int totalMs}) {
  final clampedRatio = clampUnit(ratio);
  return Duration(milliseconds: (clampedRatio * max(1, totalMs)).round());
}

Duration durationFromDistance({
  required double offset,
  required double total,
  required int totalMs,
}) {
  final ratio = ratioFromDistance(offset: offset, total: total);
  return durationFromRatio(ratio: ratio, totalMs: totalMs);
}

double toVisualAmplitude(double rawAmplitude) {
  final amplitude = rawAmplitude.abs().clamp(0.0, 1.0).toDouble();
  if (amplitude <= _noiseGate) {
    return 0.0;
  }

  final gated = ((amplitude - _noiseGate) / (1.0 - _noiseGate)).clamp(0.0, 1.0);
  final boosted = (gated * _inputGain).clamp(0.0, 1.0).toDouble();
  return pow(boosted, _shapeExponent).toDouble();
}
