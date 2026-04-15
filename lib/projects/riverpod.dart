import 'dart:convert';
import 'dart:io';

import '/preferences/riverpod.dart';
import 'package:path/path.dart' as path_tool;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/audio_sep/audio_sep.dart';
import '/llm/llm.dart';
import '/utils/utils.dart';

import 'models.dart';

part 'riverpod.g.dart';

@riverpod
class ProjectList extends _$ProjectList {
  @override
  FutureOr<List<String>> build() async {
    final directory = Directory(Project.savedDir);
    final entries = await directory
        .list()
        .map((entity) {
          final infoPath = '${entity.path}${Platform.pathSeparator}info.json';
          return File(infoPath);
        })
        .where((entity) => entity.existsSync())
        .cast<File>()
        .asyncMap(
          (file) async => (
            projectId: path_tool.basename(path_tool.dirname(file.path)),
            modifiedAt: await file.lastModified(),
          ),
        )
        .toList();
    entries.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    return entries.map((entry) => entry.projectId).toList();
  }

  PendingDeleteAction<Project>? dismiss(String id) {
    final list = state.value ?? [];
    final index = list.indexOf(id);
    if (index == -1) return null;

    final target = ref.read(projectDetailProvider(id)).value;
    if (target == null) return null;

    _removeId(id);

    return PendingDeleteAction(
      value: target,
      onUndo: () {
        final current = [...?state.value];
        current.insert(index, id);
        state = AsyncData(current);
      },
      onCommit: () async {
        // Delete cached separated audio
        await MvsepSeparationService.i.deleteCacheByAudioPath(
          target.path.audio,
        );

        // Delete project files
        final projectDir = Directory(target.path.dir);
        if (await projectDir.exists()) {
          await projectDir.delete(recursive: true);
        }
      },
    );
  }

  void _removeId(String id) {
    final previousState = state.value;
    if (previousState == null) return;

    state = AsyncData(previousState.where((e) => e != id).toList());
  }
}

@riverpod
class ProjectDetail extends _$ProjectDetail {
  @override
  Future<Project> build(String id) async {
    try {
      final file = File('${Project.savedDir}/$id/info.json');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return Project.fromJson(json);
    } catch (e) {
      Future.microtask(() {
        if (!ref.mounted) return;
        ref.read(projectListProvider.notifier)._removeId(id);
      });
      rethrow;
    }
  }

  bool _isGeneratingSummary = false;

  Future<void> generateSummaryIfAbsent() async {
    final project = state.value;
    if (project == null) return;

    if (project.summary?.isNotEmpty == true) return;
    await generateSummary();
  }

  Future<void> generateSummary() async {
    if (_isGeneratingSummary) return;

    final project = state.value;
    if (project == null) return;

    final file = File(project.path.lyric);
    if (!await file.exists()) return;

    _isGeneratingSummary = true;
    try {
      final lrc = await file.readAsString();
      final target = ref.read(translateLangProvider);
      final summary = await createSummary(lrc, target);

      await updateAndSave((old) => old.copyWith(summary: summary));
    } finally {
      _isGeneratingSummary = false;
    }
  }

  Future<void> updateLyric(String lrc, {bool isTranslate = false}) async {
    final projectPath = state.value!.path;
    final filePath = isTranslate ? projectPath.lyricT : projectPath.lyric;
    await File(filePath).writeAsString(lrc);
  }

  Future<void> updateAndSave(Project Function(Project old) updateFn) async {
    final previousState = await future;

    final newState = updateFn(previousState);

    state = AsyncData(newState);

    try {
      final dir = Directory(newState.path.dir);
      if (!await dir.exists()) await dir.create(recursive: true);

      final file = File('${newState.path.dir}/info.json');
      final data = jsonEncode(newState.toJson());
      await file.writeAsString(data);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
