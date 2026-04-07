import 'dart:io';

import 'package:flutter_lyric/core/lyric_controller.dart' as fl;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/lyric_controller/lyric_controller.dart';
import '/play_controller/play_controller.dart';
import '/projects/projects.dart';

part 'riverpod.g.dart';

@riverpod
class LyricController extends _$LyricController {
  late final PlayController playController;
  late final fl.LyricController controller;

  @override
  Future<fl.LyricController> build(String id) async {
    controller = fl.LyricController();
    ref.onDispose(() => controller.dispose());

    playController = await ref.read(playControllerProvider(id).future);
    controller.setOnTapLineCallback((position) {
      playController.seekTo(position);
      playController.startPositionNotifier.value = position;
      controller.stopSelection();
    });
    playController.positionNotifier.addListener(_updatePosition);
    ref.onDispose(
      () => playController.positionNotifier.removeListener(_updatePosition),
    );

    await _loadProjectLyric(controller);
    _updatePosition();

    return controller;
  }

  Future<void> _loadProjectLyric(fl.LyricController controller) async {
    final project = ref.read(projectDetailProvider(id)).value;
    if (project == null) return;

    controller.lyricOffset = project.lyricOffset.inMilliseconds;

    String? lrc, tlrc;
    final lrcFile = File(project.path.lyric);
    if (await lrcFile.exists()) {
      lrc = await lrcFile.readAsString();
    } else {
      return;
    }

    final tlrcFile = File(project.path.lyricT);
    if (await tlrcFile.exists()) {
      tlrc = await tlrcFile.readAsString();
    }

    controller.loadMultiLineLyric(lrc, translationLyric: tlrc);
  }

  void _updatePosition() {
    final position = playController.positionNotifier.value;
    controller.setProgress(position);
  }
}
