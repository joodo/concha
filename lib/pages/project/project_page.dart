import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../models/models.dart';
import '../../services/mvsep_separation_service.dart';
import '../../services/play_controller.dart';
import '../../waveform/waveform_controller.dart';
import '../../utils/utils.dart';
import '../../waveform/waveform.dart';
import '../../widgets/setting_button.dart';
import 'project_lyric_section.dart';
import 'project_toolbar.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({required this.project, super.key});

  final Project project;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  late final PlayController _playController;
  late final WavefromController _wavefromController;
  bool _isPreparing = true;
  String? _errorMessage;

  final _separateStreamNotifier = ValueNotifier<Stream<MvsepTaskEvent>?>(null);

  @override
  void initState() {
    super.initState();
    _playController = PlayController(audioPath: widget.project.path.audio);
    _wavefromController = WavefromController();
    _initPlayer();
    _createSeparatedAudio();
  }

  @override
  void dispose() {
    _playController.dispose();
    _wavefromController.dispose();
    _separateStreamNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: AppBar(
        title: _title.asText(),
        notificationPredicate: (notification) => false,
        actions: [const SettingButton()],
        actionsPadding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      body: _isPreparing
          ? CircularProgressIndicator().center()
          : _errorMessage != null
          ? Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.titleMedium,
            ).center()
          : [
              ProjectLyricSection(
                project: widget.project,
                playController: _playController,
              ).expanded(),
              Waveform(
                    playController: _playController,
                    waveformController: _wavefromController,
                  )
                  .backgroundColor(
                    Theme.of(context).colorScheme.surfaceContainerLow,
                  )
                  .padding(all: 12.0)
                  .constrained(height: 200.0),
              ValueListenableProvider.value(
                value: _separateStreamNotifier,
                child: ProjectToolbar(playController: _playController),
              ),
            ].toColumn(),
    );

    return FutureBuilder(
      future: ColorScheme.fromImageProvider(
        provider: FileImage(File(widget.project.path.cover)),
      ),
      initialData: Theme.of(context).colorScheme,
      builder: (context, snapshot) => Theme(
        data: Theme.of(context).copyWith(colorScheme: snapshot.data),
        child: content,
      ),
    );
  }

  Future<void> _initPlayer() async {
    try {
      await _playController.initialize();

      _playController.setStartPosition(widget.project.position);
      _playController.startPositionNotifier.addListener(
        () => widget.project.position = _playController.startPosition,
      );

      await _playController.seekTo(widget.project.position);

      if (!mounted) return;
      setState(() {
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '音频准备失败';
      });
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isPreparing = false;
        });
      }
    }
  }

  void _createSeparatedAudio() async {
    final paths = widget.project.path;

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

  String get _title {
    final data = widget.project.metadata;
    final title = data.title;
    final suffix = data.artist == null ? '' : ' - ${data.artist}';
    return '$title$suffix';
  }
}
