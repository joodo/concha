import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/waveform/waveform_controller.dart';

part 'riverpod.g.dart';

@riverpod
Raw<WaveformController> waveformController(Ref ref) {
  final controller = WaveformController();
  ref.onDispose(() => controller.dispose());
  return controller;
}

final readAloud = Mutation<Uint8List>();
