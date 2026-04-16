import 'package:flutter/widgets.dart';

import '/pages/project/actions.dart';

enum Shortcut {
  togglePlay(intent: TogglePlayIntent()),
  volumeUp(intent: DeltaVolumeIntent(0.1)),
  volumeDown(intent: DeltaVolumeIntent(-0.1)),
  seekBackward(intent: DeltaPositionIntent(-1)),
  seekForward(intent: DeltaPositionIntent(1)),
  speedDown(intent: DeltaSpeedIntent(-0.25)),
  speedUp(intent: DeltaSpeedIntent(0.25)),
  pitchDown(intent: DeltaPitchIntent(-1)),
  pitchUp(intent: DeltaPitchIntent(1)),
  mixPreset1(intent: SetMixIntent(vocalVolume: 1.0, instruVolume: 1.0)),
  mixPreset2(intent: SetMixIntent(vocalVolume: 0.4, instruVolume: 1.0)),
  mixPreset3(intent: SetMixIntent(vocalVolume: 0, instruVolume: 1.0)),
  mixPreset4(intent: SetMixIntent(vocalVolume: 1.0, instruVolume: 0.1)),
  markStart(intent: MarkStartPoint()),
  readLyric(intent: ReadAloudIntent.currentLyric());

  final Intent intent;
  const Shortcut({required this.intent});
}
