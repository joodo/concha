import 'dart:io';

import 'package:flutter_lyric/flutter_lyric.dart' as fl;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/preferences/preferences.dart';
import '/projects/projects.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/waveform/waveform_controller.dart';

part 'riverpod.g.dart';

extension ProjectExtension on WidgetRef {
  String? get projectId => context.routeArguments['id'];

  ProjectDetail? get projectNotifier =>
      projectId.mapOrNull((v) => read(projectDetailProvider(v).notifier));
  ProjectDetailProvider? get projectProvider =>
      projectId.mapOrNull((v) => projectDetailProvider(v));
  Project? get project =>
      projectId.mapOrNull((v) => read(projectDetailProvider(v)).value);

  PlayController? get playController =>
      projectId.mapOrNull((v) => read(playControllerProvider(v)).value);

  fl.LyricController? get lyricController =>
      projectId.mapOrNull((v) => read(lyricControllerProvider(v)).value);
}

@riverpod
Future<PlayController> playController(Ref ref, String id) async {
  final project = await ref.read(projectDetailProvider(id).future);

  void updateStartPos(Duration p) => ref
      .read(projectDetailProvider(id).notifier)
      .updateAndSave((old) => old.copyWith(position: p));

  final controller = PlayController(audioPath: project.path.audio);
  ref.onDispose(() => controller.dispose());

  await controller.initialize();

  controller.setStartPosition(project.position);
  controller.startPositionNotifier.addListener(
    () => updateStartPos(controller.startPosition),
  );

  await controller.seekTo(project.position);

  return controller;
}

@riverpod
Raw<WaveformController> waveformController(Ref ref) {
  final controller = WaveformController();
  ref.onDispose(() => controller.dispose());
  return controller;
}

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

    controller.loadLyric(lrc, translationLyric: tlrc);
  }

  void _updatePosition() {
    final position = playController.positionNotifier.value;
    controller.setProgress(position);
  }
}

@riverpod
class ReadAloudPending extends _$ReadAloudPending {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

@riverpod
class AttachToLyric extends _$AttachToLyric {
  @override
  bool build() => ref.watch(_pref) ?? true;

  void toggle() => set(!state);
  void set(bool value) => ref.read(_pref.notifier).set(value);

  PreferenceProvider<bool> get _pref =>
      preferenceProvider<bool>(PrefKeys.attachToLyric.value);
}

@riverpod
class Loop extends _$Loop {
  @override
  bool build() => ref.watch(_pref) ?? false;

  void toggle() => set(!state);
  void set(bool value) => ref.read(_pref.notifier).set(value);

  PreferenceProvider<bool> get _pref =>
      preferenceProvider<bool>(PrefKeys.playLoop.value);
}
