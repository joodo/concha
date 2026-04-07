import '/projects/projects.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'service.dart';

part 'riverpod.g.dart';

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
