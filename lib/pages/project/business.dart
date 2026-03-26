import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

import '/helpers.dart';
import '/models/models.dart';
import '/services/services.dart';

sealed class InitStatus {
  const InitStatus();
}

class InitSuccess extends InitStatus {
  const InitSuccess();
}

class InitFailed extends InitStatus {
  final String message;
  const InitFailed(this.message);
}

class ProjectBusiness extends SingleChildStatefulWidget {
  const ProjectBusiness({super.key, required Widget super.child});

  @override
  State<ProjectBusiness> createState() => _ProjectBusinessState();
}

class _ProjectBusinessState extends SingleChildState<ProjectBusiness> {
  late final _playController = context.read<PlayController>();
  late final _project = context.read<Project>();

  final _separateStreamNotifier = ValueNotifier<Stream<MvsepTaskEvent>?>(null);

  late final Future<InitStatus?> _initStatus;

  @override
  void initState() {
    super.initState();

    _initStatus = _initPlayer();
    _createSeparatedAudio();
    _createSummary();
  }

  @override
  void dispose() {
    _separateStreamNotifier.dispose();
    super.dispose();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return MultiProvider(
      providers: [
        ValueListenableProvider.value(value: _separateStreamNotifier),
        FutureProvider(create: (context) => _initStatus, initialData: null),
      ],
      child: child,
    );
  }

  Future<InitStatus> _initPlayer() async {
    try {
      await _playController.initialize();

      _playController.setStartPosition(_project.position);
      _playController.startPositionNotifier.addListener(
        () => _project.position = _playController.startPosition,
      );

      await _playController.seekTo(_project.position);

      return InitSuccess();
    } catch (_) {
      return InitFailed('音频准备失败');
    }
  }

  void _createSeparatedAudio() async {
    final paths = _project.path;

    late final String vocalPath, instruPath;
    if (await File(paths.audioInstru).exists() &&
        await File(paths.audioVocals).exists()) {
      vocalPath = paths.audioVocals;
      instruPath = paths.audioInstru;
    } else {
      _separateStreamNotifier.value = MvsepSeparationService.i.separate(
        audioPath: paths.audio,
        saveVocalPath: paths.audioVocals,
        saveInstruPath: paths.audioInstru,
      );

      final result = await _separateStreamNotifier.value!.last;
      if (result is MvsepCompletedEvent) {
        vocalPath = result.vocalPath;
        instruPath = result.instruPath;
      } else if (result is MvsepFailedEvent) {
        throw Exception(result.error);
      }
    }

    await _playController.setSeparatedAudio(vocalPath, instruPath);
    await _playController.setSeparateMode(true);
    _separateStreamNotifier.value = null;
  }

  Future<void> _createSummary() async {
    if (_project.summary?.isNotEmpty == true) return;
    return _project.generateSummary();
  }
}

extension ProjectBusinessExtension on Widget {
  Widget projectBusiness() => ProjectBusiness(child: this);
}
