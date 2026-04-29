import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'models.dart';

part 'riverpod.g.dart';

@riverpod
Map<Shortcut, SingleActivator?> shortcuts(Ref ref) {
  return const {
    .togglePlay: SingleActivator(.space),
    .volumeUp: SingleActivator(.arrowUp),
    .volumeDown: SingleActivator(.arrowDown),
    .seekBackward: SingleActivator(.arrowLeft),
    .seekForward: SingleActivator(.arrowRight),
    .speedDown: SingleActivator(.comma),
    .speedUp: SingleActivator(.period),
    .pitchDown: SingleActivator(.bracketLeft),
    .pitchUp: SingleActivator(.bracketRight),
    .mixPreset1: SingleActivator(.digit1),
    .mixPreset2: SingleActivator(.digit2),
    .mixPreset3: SingleActivator(.digit3),
    .mixPreset4: SingleActivator(.digit4),
    .markStart: SingleActivator(.keyZ),
    .readLyric: SingleActivator(.keyS),
  };
}
