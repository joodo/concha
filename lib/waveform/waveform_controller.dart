import 'package:flutter/foundation.dart';

class WavefromController extends ChangeNotifier {
  WavefromController({
    double scale = 1.0,
    Duration position = Duration.zero,
    Duration window = Duration.zero,
  }) : _scale = _clampScale(scale),
       _position = position,
       _window = window;

  static const double minSecondsPerTick = 0.8;
  static const double maxSecondsPerTick = 10.0;
  static const double _epsilon = 0.0001;

  double _scale;
  Duration _position;
  Duration _window;

  double get scale => _scale;
  Duration get position => _position;
  Duration get window => _window;

  set scale(double value) {
    final clamped = _clampScale(value);
    if ((clamped - _scale).abs() < _epsilon) {
      return;
    }
    _scale = clamped;
    notifyListeners();
  }

  set position(Duration value) {
    if (value == _position) {
      return;
    }
    _position = value;
    notifyListeners();
  }

  set window(Duration value) {
    if (value == _window) {
      return;
    }
    _window = value;
    notifyListeners();
  }

  static double _clampScale(double value) {
    return value.clamp(minSecondsPerTick, maxSecondsPerTick).toDouble();
  }
}
