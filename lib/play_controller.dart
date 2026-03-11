import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class PlayController implements TickerProvider {
  PlayController({required this.audioPath});

  static const int _defaultPitch = 0;
  static const double _defaultSpeed = 1.0;
  static const double _defaultVolume = 1.0;
  static const double _minSpeed = 0.05;
  static const double _speedEpsilon = 0.0001;

  final String audioPath;

  final SoLoud _soloud = SoLoud.instance;

  final ValueNotifier<bool> isPlayNotifier = ValueNotifier(false);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> startPositionNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<int> pitchNotifier = ValueNotifier(_defaultPitch);
  final ValueNotifier<double> speedNotifier = ValueNotifier(_defaultSpeed);
  final ValueNotifier<double> volumeNotifier = ValueNotifier(_defaultVolume);

  AudioSource? _source;
  SoundHandle? _handle;
  Ticker? _positionTicker;
  Duration _duration = Duration.zero;
  bool _isDisposed = false;

  bool get isInitialized => _soloud.isInitialized;
  bool get hasSource => _source != null;
  Duration get duration => _duration;
  Duration get startPosition => startPositionNotifier.value;

  void setStartPosition(Duration value) {
    if (!hasSource) {
      throw StateError(
        'PlayController is not initialized. Call initialize() before setStartPosition().',
      );
    }

    final clamped = _clampToDuration(value);
    if (clamped == startPositionNotifier.value) {
      return;
    }
    startPositionNotifier.value = clamped;
  }

  void setPitch(int value) {
    if (value == pitchNotifier.value) {
      return;
    }

    pitchNotifier.value = value;
    _applyPlaybackSettingsToActiveHandle();
  }

  void setSpeed(double value) {
    final clamped = value < _minSpeed ? _minSpeed : value;
    if (clamped == speedNotifier.value) {
      return;
    }

    speedNotifier.value = clamped;
    _applyPlaybackSettingsToActiveHandle();
  }

  void setVolume(double value) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    if (clamped == volumeNotifier.value) {
      return;
    }

    volumeNotifier.value = clamped;
    _applyPlaybackSettingsToActiveHandle();
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
    _setPosition(Duration.zero, force: true);
    _setIsPlaying(false, force: true);
    _resetPlaybackSettings();
    setStartPosition(_clampToDuration(startPosition));
    _syncPitchFilterState(source);

    _ensureTicker();
    _pauseTicker();
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
      _syncPitchFilterState(source);
      final newHandle = await _soloud.play(source);
      if (positionNotifier.value > Duration.zero) {
        _soloud.seek(newHandle, positionNotifier.value);
      }
      _applyPlaybackSettings(newHandle);
      _handle = newHandle;
      _setIsPlaying(true, force: true);
      _resumeTickerIfNeeded();
      _setPosition(positionNotifier.value, force: true);
      return;
    }

    if (_soloud.getPause(handle)) {
      _soloud.setPause(handle, false);
    }

    _setIsPlaying(true, force: true);
    _resumeTickerIfNeeded();
    _setPosition(positionNotifier.value, force: true);
  }

  Future<void> pause() async {
    if (!_soloud.isInitialized) {
      return;
    }

    final handle = _handle;
    if (handle == null || !_soloud.getIsValidVoiceHandle(handle)) {
      _setIsPlaying(false, force: true);
      _pauseTicker();
      _setPosition(positionNotifier.value, force: true);
      return;
    }

    if (!_soloud.getPause(handle)) {
      _soloud.setPause(handle, true);
    }

    _setIsPlaying(false, force: true);
    _pauseTicker();
    _setPosition(positionNotifier.value, force: true);
  }

  Future<void> togglePlayPause() async {
    if (isPlayNotifier.value) {
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
      _syncPitchFilterState(_source!);
      handle = await _soloud.play(_source!, paused: true);
      _handle = handle;
      _setIsPlaying(false);
      _pauseTicker();
      _applyPlaybackSettings(handle);
    }

    _soloud.seek(handle, clamped);
    _setPosition(clamped, force: true);
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
    _setIsPlaying(false, force: true);
    _setPosition(Duration.zero, force: true);
    _pauseTicker();
  }

  Future<void> playFromStartPoint() async {
    final source = _source;
    if (source == null || !_soloud.isInitialized) {
      return;
    }

    final target = _clampToDuration(startPosition);
    var handle = _handle;

    if (handle == null || !_soloud.getIsValidVoiceHandle(handle)) {
      _syncPitchFilterState(source);
      handle = await _soloud.play(source);
      _handle = handle;
      _applyPlaybackSettings(handle);
    } else if (_soloud.getPause(handle)) {
      _soloud.setPause(handle, false);
    }

    _soloud.seek(handle, target);
    _setPosition(target, force: true);
    _setIsPlaying(true, force: true);
    _resumeTickerIfNeeded();
  }

  void _syncPlaybackState() {
    final handle = _handle;
    if (handle == null || !_soloud.isInitialized) {
      return;
    }

    if (!_soloud.getIsValidVoiceHandle(handle)) {
      _handle = null;
      _setIsPlaying(false);
      _setPosition(_duration);
      return;
    }

    _setPosition(_soloud.getPosition(handle));
    _setIsPlaying(!_soloud.getPause(handle));
  }

  void _onPositionTick(Duration _) {
    if (_isDisposed || !_soloud.isInitialized) {
      return;
    }

    _syncPlaybackState();

    if (!isPlayNotifier.value) {
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
    if (_isDisposed || !_soloud.isInitialized || !isPlayNotifier.value) {
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

  void _resetPlaybackSettings() {
    pitchNotifier.value = _defaultPitch;
    speedNotifier.value = _defaultSpeed;
    volumeNotifier.value = _defaultVolume;
  }

  void _applyPlaybackSettingsToActiveHandle() {
    final handle = _handle;
    if (handle == null || !_soloud.isInitialized) {
      return;
    }

    if (!_soloud.getIsValidVoiceHandle(handle)) {
      return;
    }

    _applyPlaybackSettings(handle);
  }

  void _applyPlaybackSettings(SoundHandle handle) {
    _soloud.setRelativePlaySpeed(handle, speedNotifier.value);
    _soloud.setVolume(handle, volumeNotifier.value);
    _applyPitch(handle);
  }

  void _applyPitch(SoundHandle handle) {
    final source = _source;
    if (source == null) {
      return;
    }

    _syncPitchFilterState(source);
    final pitchShiftFilter = source.filters.pitchShiftFilter;
    if (!pitchShiftFilter.isActive) {
      return;
    }

    pitchShiftFilter.wet(soundHandle: handle).value = _shouldUsePitchShiftFilter
        ? 1.0
        : 0.0;
    pitchShiftFilter.semitones(soundHandle: handle).value =
        _shouldUsePitchShiftFilter ? _effectivePitchSemitones : 0.0;
  }

  void _syncPitchFilterState(AudioSource source) {
    final pitchShiftFilter = source.filters.pitchShiftFilter;
    if (!pitchShiftFilter.isActive) {
      pitchShiftFilter.activate();
    }

    pitchShiftFilter.wet().value = _shouldUsePitchShiftFilter ? 1.0 : 0.0;
    pitchShiftFilter.semitones().value = _shouldUsePitchShiftFilter
        ? _effectivePitchSemitones
        : 0.0;
  }

  bool get _shouldUsePitchShiftFilter {
    final speedDelta = (speedNotifier.value - _defaultSpeed).abs();
    return pitchNotifier.value != _defaultPitch || speedDelta > _speedEpsilon;
  }

  double get _effectivePitchSemitones {
    // Compensate speed-induced pitch shift so speed changes keep target pitch.
    final speedSemitoneShift = 12 * (math.log(speedNotifier.value) / math.ln2);
    return pitchNotifier.value - speedSemitoneShift;
  }

  void _setPosition(Duration value, {bool force = false}) {
    if (_isDisposed) {
      return;
    }

    if (positionNotifier.value == value) {
      return;
    }

    positionNotifier.value = value;
  }

  void _setIsPlaying(bool value, {bool force = false}) {
    if (_isDisposed) {
      return;
    }

    if (isPlayNotifier.value == value) {
      return;
    }

    isPlayNotifier.value = value;
  }

  void dispose() {
    _isDisposed = true;
    _pauseTicker();
    _positionTicker?.dispose();
    _positionTicker = null;

    final handle = _handle;
    final source = _source;

    _source = null;
    _handle = null;

    unawaited(_disposeAudioResources(handle: handle, source: source));

    isPlayNotifier.dispose();
    positionNotifier.dispose();
    startPositionNotifier.dispose();
    pitchNotifier.dispose();
    speedNotifier.dispose();
    volumeNotifier.dispose();
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
