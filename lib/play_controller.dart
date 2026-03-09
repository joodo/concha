import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class PlayController extends ChangeNotifier implements TickerProvider {
  PlayController({required this.audioPath});

  final String audioPath;

  final SoLoud _soloud = SoLoud.instance;

  AudioSource? _source;
  SoundHandle? _handle;
  Ticker? _positionTicker;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _startPosition = Duration.zero;
  bool _isPlaying = false;
  Duration? _lastEmittedPosition;
  bool? _lastEmittedPlaying;
  bool _isDisposed = false;

  bool get isInitialized => _soloud.isInitialized;
  bool get hasSource => _source != null;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get startPosition => _startPosition;

  set startPosition(Duration value) {
    final clamped = _clampToDuration(value);
    if (clamped == _startPosition) {
      return;
    }
    _startPosition = clamped;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (!_soloud.isInitialized) {
      throw StateError(
        'SoLoud is not initialized. Call SoLoud.instance.init() in main() first.',
      );
    }

    final source = await _soloud.loadFile(audioPath);
    final duration = _soloud.getLength(source);

    _source = source;
    _duration = duration;
    _position = Duration.zero;
    _startPosition = _clampToDuration(_startPosition);
    _isPlaying = false;

    _ensureTicker();
    _pauseTicker();
    _emitPosition(force: true);
  }

  Future<List<double>> loadSamples({
    required Duration start,
    required Duration end,
    required int sampleCount,
  }) async {
    if (!_soloud.isInitialized) {
      return const [];
    }

    final clampedStart = _clampToDuration(start);
    final clampedEnd = _clampToDuration(end);
    if (clampedEnd <= clampedStart) {
      return const [];
    }

    final samples = await _soloud.readSamplesFromFile(
      audioPath,
      sampleCount,
      startTime: clampedStart.inMilliseconds / 1000,
      endTime: clampedEnd.inMilliseconds / 1000,
      average: true,
    );
    return samples;
  }

  Future<void> play() async {
    final source = _source;
    if (source == null || !_soloud.isInitialized) {
      return;
    }

    final handle = _handle;
    if (handle == null || !_soloud.getIsValidVoiceHandle(handle)) {
      final newHandle = await _soloud.play(source);
      if (_position > Duration.zero) {
        _soloud.seek(newHandle, _position);
      }
      _handle = newHandle;
      _isPlaying = true;
      _resumeTickerIfNeeded();
      _emitPosition(force: true);
      return;
    }

    if (_soloud.getPause(handle)) {
      _soloud.setPause(handle, false);
    }

    _isPlaying = true;
    _resumeTickerIfNeeded();
    _emitPosition(force: true);
  }

  Future<void> pause() async {
    if (!_soloud.isInitialized) {
      return;
    }

    final handle = _handle;
    if (handle == null || !_soloud.getIsValidVoiceHandle(handle)) {
      _isPlaying = false;
      _pauseTicker();
      _emitPosition(force: true);
      return;
    }

    if (!_soloud.getPause(handle)) {
      _soloud.setPause(handle, true);
    }

    _isPlaying = false;
    _pauseTicker();
    _emitPosition(force: true);
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
      return;
    }

    await play();
  }

  Future<void> seekTo(Duration target) async {
    if (_source == null || !_soloud.isInitialized) {
      return;
    }

    final clamped = _clampToDuration(target);

    var handle = _handle;
    if (handle == null || !_soloud.getIsValidVoiceHandle(handle)) {
      handle = await _soloud.play(_source!, paused: true);
      _handle = handle;
      _isPlaying = false;
      _pauseTicker();
    }

    _soloud.seek(handle, clamped);
    _position = clamped;
    _emitPosition(force: true);
  }

  Future<void> stop() async {
    if (!_soloud.isInitialized) {
      return;
    }

    final handle = _handle;
    if (handle != null && _soloud.getIsValidVoiceHandle(handle)) {
      await _soloud.stop(handle);
    }

    _handle = null;
    _isPlaying = false;
    _position = Duration.zero;
    _pauseTicker();
    _emitPosition(force: true);
  }

  Future<void> playFromStartPoint() async {
    final source = _source;
    if (source == null || !_soloud.isInitialized) {
      return;
    }

    final target = _clampToDuration(_startPosition);
    var handle = _handle;

    if (handle == null || !_soloud.getIsValidVoiceHandle(handle)) {
      handle = await _soloud.play(source);
      _handle = handle;
    } else if (_soloud.getPause(handle)) {
      _soloud.setPause(handle, false);
    }

    _soloud.seek(handle, target);
    _position = target;
    _isPlaying = true;
    _resumeTickerIfNeeded();
    _emitPosition(force: true);
  }

  void _syncPlaybackState() {
    final handle = _handle;
    if (handle == null || !_soloud.isInitialized) {
      return;
    }

    if (!_soloud.getIsValidVoiceHandle(handle)) {
      _handle = null;
      _isPlaying = false;
      _position = _duration;
      return;
    }

    _position = _soloud.getPosition(handle);
    _isPlaying = !_soloud.getPause(handle);
  }

  void _onPositionTick(Duration _) {
    if (_isDisposed || !_soloud.isInitialized) {
      return;
    }

    _syncPlaybackState();
    _emitPosition();

    if (!_isPlaying) {
      _pauseTicker();
    }
  }

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = Ticker(onTick, debugLabel: 'PlayController.positionTicker');
    _positionTicker = ticker;
    return ticker;
  }

  void _ensureTicker() {
    _positionTicker ??= createTicker(_onPositionTick);
  }

  void _resumeTickerIfNeeded() {
    if (_isDisposed || !_soloud.isInitialized || !_isPlaying) {
      return;
    }

    _ensureTicker();
    final ticker = _positionTicker;
    if (ticker == null || ticker.isActive) {
      return;
    }
    ticker.start();
  }

  void _pauseTicker() {
    final ticker = _positionTicker;
    if (ticker == null || !ticker.isActive) {
      return;
    }
    ticker.stop(canceled: false);
  }

  void _emitPosition({bool force = false}) {
    if (_isDisposed) {
      return;
    }

    if (!force &&
        _lastEmittedPosition == _position &&
        _lastEmittedPlaying == _isPlaying) {
      return;
    }

    _lastEmittedPosition = _position;
    _lastEmittedPlaying = _isPlaying;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pauseTicker();
    _positionTicker?.dispose();
    _positionTicker = null;

    final handle = _handle;
    final source = _source;

    _source = null;
    _handle = null;
    _isPlaying = false;

    unawaited(_disposeAudioResources(handle: handle, source: source));
    super.dispose();
  }

  Future<void> _disposeAudioResources({
    required SoundHandle? handle,
    required AudioSource? source,
  }) async {
    if (!_soloud.isInitialized) {
      return;
    }

    if (handle != null && _soloud.getIsValidVoiceHandle(handle)) {
      await _soloud.stop(handle);
    }

    if (source != null) {
      await _soloud.disposeSource(source);
    }
  }

  Duration _clampToDuration(Duration target) {
    if (target < Duration.zero) {
      return Duration.zero;
    }
    if (target > _duration) {
      return _duration;
    }
    return target;
  }
}
