class PlaybackBindingState {
  bool isBound = true;
  bool _waitForPauseBeforeRebind = false;
  bool _lastPlayingState = false;

  void reset(bool isPlaying) {
    isBound = true;
    _waitForPauseBeforeRebind = false;
    _lastPlayingState = isPlaying;
  }

  void detach(bool isPlaying) {
    isBound = false;
    _waitForPauseBeforeRebind = isPlaying;
    _lastPlayingState = isPlaying;
  }

  void handlePlayState(bool isPlaying) {
    if (isBound) {
      _lastPlayingState = isPlaying;
      return;
    }

    if (_waitForPauseBeforeRebind) {
      if (!isPlaying) {
        _waitForPauseBeforeRebind = false;
      }
      _lastPlayingState = isPlaying;
      return;
    }

    if (!_lastPlayingState && isPlaying) {
      isBound = true;
    }
    _lastPlayingState = isPlaying;
  }
}
