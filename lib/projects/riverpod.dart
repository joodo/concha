import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:path/path.dart' as path_tool;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/lyric/lyric.dart';
import '/persistence/persistence.dart';
import '/preferences/riverpod.dart';
import '/utils/utils.dart';

import 'models.dart';

part 'riverpod.g.dart';

@riverpod
class ProjectList extends _$ProjectList {
  @override
  FutureOr<List<String>> build() async {
    final directory = Directory(Project.savedDir);

    final ids = await directory
        .list()
        .map((entity) => path_tool.basename(entity.path))
        .asyncWhere(
          (e) => ref.read(projectDetailProvider(e).notifier)._isValid(),
        )
        .toList();

    final lastVisited = {
      for (final id in ids)
        id: await ref.read(projectLastVisitedProvider(id).future),
    };
    ids.sort((a, b) => lastVisited[b]!.compareTo(lastVisited[a]!));

    return ids;
  }

  Future<void> visit(String id) async {
    final previousState = await future;
    final index = previousState.indexOf(id);
    if (index == -1) return;

    state = AsyncData([
      previousState[index],
      ...previousState.take(index),
      ...previousState.skip(index + 1),
    ]);

    await ref.read(projectLastVisitedProvider(id).notifier)._updateNow();
  }

  Future<PendingDeleteAction<Project>?> dismiss(String id) async {
    final target = await ref.read(projectDetailProvider(id).future);

    final previousState = await future;
    final index = previousState.indexOf(id);
    if (index == -1) return null;
    state = AsyncData([
      ...previousState.take(index),
      ...previousState.skip(index + 1),
    ]);

    return PendingDeleteAction(
      value: target,
      onUndo: () {
        final current = [...?state.value];
        current.insert(index, id);
        state = AsyncData(current);
      },
      onCommit: () async {
        // Delete providers
        await ref.read(projectDetailProvider(id).notifier)._delete();
        await ref.read(projectLastVisitedProvider(id).notifier)._delete();
      },
    );
  }
}

@riverpod
class ProjectDetail extends _$ProjectDetail {
  @override
  Future<Project> build(String id) async {
    final file = File(ProjectPath(id).info);
    final content = await file.readAsString();
    final json = jsonDecode(content) as JsonMap;
    return Project.fromJson(json);
  }

  Future<bool> _isValid() async {
    // During initialization, ProjectList will first "touch" all available ProjectDetail instances to filter for valid ones.
    // Subsequently, the UI layer will watch the ProjectDetailProvider to keep it alive.
    // A 3-second cache is implemented for ProjectDetailProvider to ensure the UI can re-attach without re-parsing the JSON file
    ref.cacheFor(3.seconds);
    try {
      await future;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isGeneratingSummary = false;

  Future<void> generateSummaryIfAbsent() async {
    final project = await future;
    if (project.summary?.isNotEmpty == true) return;
    await generateSummary();
  }

  Future<void> generateSummary() async {
    if (_isGeneratingSummary) return;
    _isGeneratingSummary = true;

    final project = await future;
    final file = File(project.path.lyric);
    if (!await file.exists()) return;

    try {
      final lrc = await file.readAsString();
      final targetLang = ref.read(translateLangProvider);
      final summary = await createSummary(lrc, targetLang);

      await updateAndSave((old) => old.copyWith(summary: summary));
    } finally {
      _isGeneratingSummary = false;
    }
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

  Future<void> _delete() async {
    final path = ProjectPath(id).dir;
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    if (ref.mounted) ref.invalidateSelf();
  }
}

@riverpod
class ProjectLastVisited extends _$ProjectLastVisited with LoadPersistOrFetch {
  @override
  FutureOr<DateTime> build(String id) {
    return loadPersistOrFetch(
      persist: persist(
        ref.watch(persistStorageProvider.future),
        key: _persistKey,
        encode: (state) => state.toString(),
        decode: (encoded) => DateTime.parse(encoded),
        options: const StorageOptions(
          cacheTime: StorageCacheTime.unsafe_forever,
        ),
      ),
      fetch: () => File(ProjectPath(id).info).lastModified(),
    );
  }

  Future<void> _updateNow() async {
    await future;
    state = AsyncData(DateTime.now());
  }

  Future<void> _delete() async {
    final storage = await ref.read(persistStorageProvider.future);
    await storage.delete(_persistKey);
    if (ref.mounted) ref.invalidateSelf();
  }

  String get _persistKey => 'ProjectLastVisit($id)';
}

@riverpod
class ProjectCoverBytes extends _$ProjectCoverBytes {
  @override
  Future<Uint8List?> build(String id) async {
    final file = _file;
    if (!await file.exists()) return null;

    return await file.readAsBytes();
  }

  Future<void> set(Uint8List data) async {
    await _file.writeAsBytes(data);
    state = AsyncValue.data(data);
  }

  File get _file => File(ProjectPath(id).cover);
}
