import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/waveform/waveform_controller.dart';

part 'riverpod.g.dart';

@riverpod
Raw<WaveformController> waveformController(Ref ref) {
  final controller = WaveformController();
  ref.onDispose(() => controller.dispose());
  return controller;
}

@riverpod
class ReadAloudPending extends _$ReadAloudPending {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}
