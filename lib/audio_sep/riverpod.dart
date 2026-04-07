import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/projects/projects.dart';

import 'mvsep_separation_service.dart';

part 'riverpod.g.dart';

@riverpod
Stream<MvsepTaskEvent> sepAudioEvent(Ref ref, String id) async* {
  final project = await ref.read(projectDetailProvider(id).future);

  final paths = project.path;
  if (await File(paths.audioInstru).exists() &&
      await File(paths.audioVocals).exists()) {
    yield MvsepCompletedEvent(
      audioPath: project.path.audio,
      vocalPath: paths.audioVocals,
      instruPath: paths.audioInstru,
    );
    return;
  }

  yield* MvsepSeparationService.i.separate(
    audioPath: paths.audio,
    saveVocalPath: paths.audioVocals,
    saveInstruPath: paths.audioInstru,
  );
}
