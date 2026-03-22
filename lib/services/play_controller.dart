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
  static const double _defaultVocalVolume = 1.0;
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
  final ValueNotifier<double> vocalVolumeNotifier = ValueNotifier(
    _defaultVocalVolume,
  );
  final ValueNotifier<bool> separateModeNotifier = ValueNotifier(false);

  AudioSource? _source;
  SoundHandle? _handle;
  AudioSource? _separatedVocalSource;
  AudioSource? _separatedInstruSource;
  SoundHandle? _separatedVocalHandle;
  SoundHandle? _separatedInstruHandle;
  AudioSource? _interludeSource;
  SoundHandle? _interludeHandle;
  int? _interludeFingerprint;
  int _interludeCounter = 0;
  Ticker? _positionTicker;
  Duration _duration = Duration.zero;
  bool _isDisposed = false;

  bool get isInitialized => _soloud.isInitialized;
  bool get hasSource => _source != null;
  bool get isSeparateMode => separateModeNotifier.value;
  Duration get duration => _duration;
  Duration get startPosition => startPositionNotifier.value;

  Future<void> setSeparatedAudio(
    String vocalAudioPath,
    String instruAudioPath,
  ) async {
    if (!_soloud.isInitialized) {
      throw StateError(
        'SoLoud is not initialized. Call SoLoud.instance.init() in main() first.',
      );
    }

    final vocalPath = vocalAudioPath.trim();
    final instruPath = instruAudioPath.trim();
    if (vocalPath.isEmpty || instruPath.isEmpty) {
      throw ArgumentError('Separated audio paths must not be empty.');
    }

    final wasPlaying = isPlayNotifier.value;
    final keepPosition = positionNotifier.value;

    await _stopSeparatedHandles();
    await _disposeSeparatedSources();

    _separatedVocalSource = await _soloud.loadFile(vocalPath);
    _separatedInstruSource = await _soloud.loadFile(instruPath);

    _syncPitchFilterState(_separatedVocalSource!);
    _syncPitchFilterState(_separatedInstruSource!);

    if (isSeparateMode) {
      if (wasPlaying) {
        _setPosition(keepPosition, force: true);
        await play();
      } else {
        await seekTo(keepPosition);
      }
    }
  }

  Future<void> setSeparateMode(bool enabled) async {
    if (enabled == separateModeNotifier.value) {
      return;
    }

    if (enabled && !_hasSeparatedSources) {
      throw StateError(
        'Separated audio is not ready. Call setSeparatedAudio() first.',
      );
    }

    final keepPosition = positionNotifier.value;
    final wasPlaying = isPlayNotifier.value;

    separateModeNotifier.value = enabled;

    if (enabled) {
      await _stopOriginalHandle();
    } else {
      await _stopSeparatedHandles();
    }

    _setPosition(keepPosition, force: true);
    if (wasPlaying) {
      await play();
    } else {
      await seekTo(keepPosition);
      _setIsPlaying(false, force: true);
      _pauseTicker();
    }
  }

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
    _applyVolumeToInterludeHandle();
  }

  void setVocalVolume(double value) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    if (clamped == vocalVolumeNotifier.value) {
      return;
    }

    vocalVolumeNotifier.value = clamped;
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
    if (!_soloud.isInitialized) {
      return;
    }

    _stopInterlude();

    if (isSeparateMode) {
      await _playSeparated();
      return;
    }

    final source = _source;
    if (source == null) {
      return;
    }

    final handle = _handle;
    if (handle == null || !_soloud.getIsValidVoiceHandle(handle)) {
      _syncPitchFilterState(source);
      final newHandle = await _soloud.play(source);
      if (positionNotifier.value > Duration.zero) {
        _soloud.seek(newHandle, positionNotifier.value);
      }
      _applyPlaybackSettings(
        handle: newHandle,
        source: source,
        volumeScale: 1.0,
      );
      _handle = newHandle;
      _markPlayingAtCurrentPosition();
      return;
    }

    if (_soloud.getPause(handle)) {
      _soloud.setPause(handle, false);
    }

    _markPlayingAtCurrentPosition();
  }

  Future<void> pause() async {
    if (!_soloud.isInitialized) {
      return;
    }

    if (isSeparateMode) {
      await _pauseSeparated();
      return;
    }

    final handle = _handle;
    if (handle == null || !_soloud.getIsValidVoiceHandle(handle)) {
      _markPausedAtCurrentPosition();
      return;
    }

    if (!_soloud.getPause(handle)) {
      _soloud.setPause(handle, true);
    }

    _markPausedAtCurrentPosition();
  }

  Future<void> togglePlayPause() async {
    if (isPlayNotifier.value) {
      await pause();
      return;
    }

    await play();
  }

  Future<void> interlude(Uint8List voiceBytes) => insertInterlude(voiceBytes);

  Future<void> insertInterlude(Uint8List voiceBytes) async {
    if (!_soloud.isInitialized) {
      return;
    }

    if (voiceBytes.isEmpty) {
      throw ArgumentError.value(voiceBytes, 'voiceBytes', '不能为空');
    }

    final nextFingerprint = _fingerprintBytes(voiceBytes);
    if (_isSameInterlude(nextFingerprint)) {
      await _stopInterlude();
      return;
    }

    await _stopInterlude();

    await _disposeInterludeSource();

    final path = 'interlude_${_interludeCounter++}.wav';
    final source = await _soloud.loadMem(path, voiceBytes);
    final handle = await _soloud.play(source, volume: volumeNotifier.value);

    _interludeSource = source;
    _interludeHandle = handle;
    _interludeFingerprint = nextFingerprint;
  }

  Future<void> seekTo(Duration target) async {
    if (!_soloud.isInitialized) {
      return;
    }

    if (isSeparateMode) {
      await _seekSeparated(target);
      return;
    }

    if (_source == null) {
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
      _applyPlaybackSettings(handle: handle, source: _source, volumeScale: 1.0);
    }

    _soloud.seek(handle, clamped);
    _setPosition(clamped, force: true);
  }

  Future<void> stop() async {
    if (!_soloud.isInitialized) {
      return;
    }

    if (isSeparateMode) {
      await _stopSeparatedHandles();
    } else {
      await _stopOriginalHandle();
    }

    _setIsPlaying(false, force: true);
    _setPosition(Duration.zero, force: true);
    setStartPosition(Duration.zero);
    _pauseTicker();
  }

  Future<void> playFromStartPoint() async {
    if (!_soloud.isInitialized) {
      return;
    }

    final target = _clampToDuration(startPosition);

    await seekTo(target);
    await play();
  }

  void _syncPlaybackState() {
    final handle = _masterHandle;
    if (handle == null || !_soloud.isInitialized) {
      return;
    }

    if (!_soloud.getIsValidVoiceHandle(handle)) {
      if (isSeparateMode) {
        _separatedInstruHandle = null;
        _separatedVocalHandle = null;
      } else {
        _handle = null;
      }
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

  void _markPlayingAtCurrentPosition() {
    _setIsPlaying(true, force: true);
    _resumeTickerIfNeeded();
    _setPosition(positionNotifier.value, force: true);
  }

  void _markPausedAtCurrentPosition() {
    _setIsPlaying(false, force: true);
    _pauseTicker();
    _setPosition(positionNotifier.value, force: true);
  }

  void _resetPlaybackSettings() {
    pitchNotifier.value = _defaultPitch;
    speedNotifier.value = _defaultSpeed;
    volumeNotifier.value = _defaultVolume;
    vocalVolumeNotifier.value = _defaultVocalVolume;
    separateModeNotifier.value = false;
  }

  void _applyPlaybackSettingsToActiveHandle() {
    if (!_soloud.isInitialized) {
      return;
    }

    if (isSeparateMode) {
      final instruHandle = _separatedInstruHandle;
      if (instruHandle != null && _soloud.getIsValidVoiceHandle(instruHandle)) {
        _applyPlaybackSettings(
          handle: instruHandle,
          source: _separatedInstruSource,
          volumeScale: 1.0,
        );
      }

      final vocalHandle = _separatedVocalHandle;
      if (vocalHandle != null && _soloud.getIsValidVoiceHandle(vocalHandle)) {
        _applyPlaybackSettings(
          handle: vocalHandle,
          source: _separatedVocalSource,
          volumeScale: vocalVolumeNotifier.value,
        );
      }
      return;
    }

    final handle = _handle;
    if (handle == null || !_soloud.getIsValidVoiceHandle(handle)) {
      return;
    }

    _applyPlaybackSettings(handle: handle, source: _source, volumeScale: 1.0);
  }

  void _applyPlaybackSettings({
    required SoundHandle handle,
    required AudioSource? source,
    required double volumeScale,
  }) {
    _soloud.setRelativePlaySpeed(handle, speedNotifier.value);
    _soloud.setVolume(
      handle,
      (volumeNotifier.value * volumeScale).clamp(0.0, 1.0),
    );
    _applyPitch(handle, source);
  }

  void _applyVolumeToInterludeHandle() {
    final handle = _interludeHandle;
    if (handle == null || !_soloud.isInitialized) {
      return;
    }

    if (!_soloud.getIsValidVoiceHandle(handle)) {
      return;
    }

    _soloud.setVolume(handle, volumeNotifier.value);
  }

  void _applyPitch(SoundHandle handle, AudioSource? source) {
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
    final separatedVocalHandle = _separatedVocalHandle;
    final separatedInstruHandle = _separatedInstruHandle;
    final separatedVocalSource = _separatedVocalSource;
    final separatedInstruSource = _separatedInstruSource;
    final interludeHandle = _interludeHandle;
    final interludeSource = _interludeSource;

    _source = null;
    _handle = null;
    _separatedVocalSource = null;
    _separatedInstruSource = null;
    _separatedVocalHandle = null;
    _separatedInstruHandle = null;
    _interludeSource = null;
    _interludeHandle = null;
    _interludeFingerprint = null;

    unawaited(
      _disposeAudioResources(
        handle: handle,
        source: source,
        separatedVocalHandle: separatedVocalHandle,
        separatedInstruHandle: separatedInstruHandle,
        separatedVocalSource: separatedVocalSource,
        separatedInstruSource: separatedInstruSource,
        interludeHandle: interludeHandle,
        interludeSource: interludeSource,
      ),
    );

    isPlayNotifier.dispose();
    positionNotifier.dispose();
    startPositionNotifier.dispose();
    pitchNotifier.dispose();
    speedNotifier.dispose();
    volumeNotifier.dispose();
    vocalVolumeNotifier.dispose();
    separateModeNotifier.dispose();
  }

  Future<void> _disposeAudioResources({
    required SoundHandle? handle,
    required AudioSource? source,
    required SoundHandle? separatedVocalHandle,
    required SoundHandle? separatedInstruHandle,
    required AudioSource? separatedVocalSource,
    required AudioSource? separatedInstruSource,
    required SoundHandle? interludeHandle,
    required AudioSource? interludeSource,
  }) async {
    if (!_soloud.isInitialized) {
      return;
    }

    await _stopIfValid(handle);
    await _stopIfValid(interludeHandle);
    await _stopIfValid(separatedVocalHandle);
    await _stopIfValid(separatedInstruHandle);

    if (source != null) {
      await _soloud.disposeSource(source);
    }

    if (separatedVocalSource != null) {
      await _soloud.disposeSource(separatedVocalSource);
    }

    if (separatedInstruSource != null) {
      await _soloud.disposeSource(separatedInstruSource);
    }

    if (interludeSource != null) {
      await _soloud.disposeSource(interludeSource);
    }
  }

  bool get _hasActiveInterlude {
    final handle = _interludeHandle;
    if (handle == null || !_soloud.isInitialized) {
      return false;
    }

    return _soloud.getIsValidVoiceHandle(handle);
  }

  Future<void> _stopInterlude() async {
    if (!_soloud.isInitialized) {
      return;
    }

    final handle = _interludeHandle;
    _interludeHandle = null;
    _interludeFingerprint = null;
    await _stopIfValid(handle);

    await _disposeInterludeSource();
  }

  Future<void> _disposeInterludeSource() async {
    if (!_soloud.isInitialized) {
      return;
    }

    final source = _interludeSource;
    _interludeSource = null;
    if (source == null) {
      return;
    }

    await _soloud.disposeSource(source);
  }

  bool _isSameInterlude(int fingerprint) {
    if (!_hasActiveInterlude) {
      return false;
    }

    return _interludeFingerprint == fingerprint;
  }

  int _fingerprintBytes(Uint8List bytes) {
    var hash = 0x811C9DC5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
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

  SoundHandle? get _masterHandle =>
      isSeparateMode ? _separatedInstruHandle : _handle;

  bool get _hasSeparatedSources =>
      _separatedVocalSource != null && _separatedInstruSource != null;

  Future<void> _playSeparated() async {
    if (!_hasSeparatedSources) {
      return;
    }

    var instruHandle = _separatedInstruHandle;
    var vocalHandle = _separatedVocalHandle;

    final hasValidInstru =
        instruHandle != null && _soloud.getIsValidVoiceHandle(instruHandle);
    final hasValidVocal =
        vocalHandle != null && _soloud.getIsValidVoiceHandle(vocalHandle);

    if (!hasValidInstru || !hasValidVocal) {
      await _stopIfValid(instruHandle);
      await _stopIfValid(vocalHandle);

      _syncPitchFilterState(_separatedInstruSource!);
      _syncPitchFilterState(_separatedVocalSource!);
      instruHandle = await _soloud.play(_separatedInstruSource!);
      vocalHandle = await _soloud.play(_separatedVocalSource!);
      _separatedInstruHandle = instruHandle;
      _separatedVocalHandle = vocalHandle;

      if (positionNotifier.value > Duration.zero) {
        _soloud.seek(instruHandle, positionNotifier.value);
        _soloud.seek(vocalHandle, positionNotifier.value);
      }

      _applyPlaybackSettingsToActiveHandle();
      _markPlayingAtCurrentPosition();
      return;
    }

    if (_soloud.getPause(instruHandle)) {
      _soloud.setPause(instruHandle, false);
    }
    if (_soloud.getPause(vocalHandle)) {
      _soloud.setPause(vocalHandle, false);
    }

    _applyPlaybackSettingsToActiveHandle();
    _markPlayingAtCurrentPosition();
  }

  Future<void> _pauseSeparated() async {
    final instruHandle = _separatedInstruHandle;
    final vocalHandle = _separatedVocalHandle;
    final hasValidInstru =
        instruHandle != null && _soloud.getIsValidVoiceHandle(instruHandle);
    final hasValidVocal =
        vocalHandle != null && _soloud.getIsValidVoiceHandle(vocalHandle);

    if (!hasValidInstru || !hasValidVocal) {
      _markPausedAtCurrentPosition();
      return;
    }

    if (!_soloud.getPause(instruHandle)) {
      _soloud.setPause(instruHandle, true);
    }
    if (!_soloud.getPause(vocalHandle)) {
      _soloud.setPause(vocalHandle, true);
    }

    _markPausedAtCurrentPosition();
  }

  Future<void> _seekSeparated(Duration target) async {
    if (!_hasSeparatedSources) {
      return;
    }

    final clamped = _clampToDuration(target);
    var instruHandle = _separatedInstruHandle;
    var vocalHandle = _separatedVocalHandle;

    final hasValidInstru =
        instruHandle != null && _soloud.getIsValidVoiceHandle(instruHandle);
    final hasValidVocal =
        vocalHandle != null && _soloud.getIsValidVoiceHandle(vocalHandle);

    if (!hasValidInstru || !hasValidVocal) {
      await _stopIfValid(instruHandle);
      await _stopIfValid(vocalHandle);

      _syncPitchFilterState(_separatedInstruSource!);
      _syncPitchFilterState(_separatedVocalSource!);
      instruHandle = await _soloud.play(_separatedInstruSource!, paused: true);
      vocalHandle = await _soloud.play(_separatedVocalSource!, paused: true);
      _separatedInstruHandle = instruHandle;
      _separatedVocalHandle = vocalHandle;
      _setIsPlaying(false);
      _pauseTicker();
      _applyPlaybackSettingsToActiveHandle();
    }

    _soloud.seek(instruHandle, clamped);
    _soloud.seek(vocalHandle, clamped);
    _setPosition(clamped, force: true);
  }

  Future<void> _stopOriginalHandle() async {
    final handle = _handle;
    await _stopIfValid(handle);
    _handle = null;
  }

  Future<void> _stopSeparatedHandles() async {
    final instruHandle = _separatedInstruHandle;
    final vocalHandle = _separatedVocalHandle;

    await _stopIfValid(instruHandle);
    await _stopIfValid(vocalHandle);

    _separatedInstruHandle = null;
    _separatedVocalHandle = null;
  }

  Future<void> _stopIfValid(SoundHandle? handle) async {
    if (handle == null) {
      return;
    }

    if (_soloud.getIsValidVoiceHandle(handle)) {
      await _soloud.stop(handle);
    }
  }

  Future<void> _disposeSeparatedSources() async {
    if (!_soloud.isInitialized) {
      return;
    }

    final vocalSource = _separatedVocalSource;
    final instruSource = _separatedInstruSource;
    _separatedVocalSource = null;
    _separatedInstruSource = null;

    if (vocalSource != null) {
      await _soloud.disposeSource(vocalSource);
    }
    if (instruSource != null) {
      await _soloud.disposeSource(instruSource);
    }
  }
}
