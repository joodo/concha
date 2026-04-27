import 'dart:io';

import 'package:flutter_lyric/core/lyric_controller.dart' as fl;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/play_controller/play_controller.dart';
import '/projects/projects.dart';

import 'extensions.dart';

part 'riverpod.g.dart';

@riverpod
class LyricController extends _$LyricController {
  late final PlayController playController;
  late final fl.LyricController controller;

  String? _lrc, _tlrc;

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

    final project = await ref.read(projectDetailProvider(id).future);
    controller.lyricOffset = project.lyricOffset.inMilliseconds;

    ref.listen(lyricProvider(id, isTranslate: false), (previous, next) {
      _lrc = next.value;
      controller.loadMultiLineLyric(_lrc, translationLyric: _tlrc);
    });
    ref.listen(lyricProvider(id, isTranslate: true), (previous, next) {
      _tlrc = next.value;
      controller.loadMultiLineLyric(_lrc, translationLyric: _tlrc);
    });
    _updatePosition();

    return controller;
  }

  void _updatePosition() {
    final position = playController.positionNotifier.value;
    controller.setProgress(position);
  }
}

@riverpod
class Lyric extends _$Lyric {
  @override
  Future<String?> build(String id, {required bool isTranslate}) async {
    final file = File(_filePath);

    if (!await file.exists()) return null;
    return await file.readAsString();
  }

  void preview(String lyric) {
    state = AsyncData(lyric);
  }

  Future<void> save(String lyric) async {
    final file = File(_filePath);
    await file.writeAsString(lyric);
    state = AsyncData(lyric);
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  void clearTemporarily() async {
    state = AsyncData(null);
  }

  String get _filePath =>
      isTranslate ? ProjectPath(id).lyricT : ProjectPath(id).lyric;
}
