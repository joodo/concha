import 'dart:io';

import 'package:animations/animations.dart';
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
import 'actions.dart';
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
        actions: [const _HelpButton(), const SettingButton()],
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

    final body = content.projectActions(controller: _playController);

    return FutureBuilder(
      future: ColorScheme.fromImageProvider(
        provider: FileImage(File(widget.project.path.cover)),
      ),
      initialData: Theme.of(context).colorScheme,
      builder: (context, snapshot) => Theme(
        data: Theme.of(context).copyWith(colorScheme: snapshot.data),
        child: body,
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

class _HelpButton extends StatelessWidget {
  static const List<(String, String)> _shortcutItems = [
    ('Space', '从起点播放/暂停'),
    ('Shift + Space', '继续播放/暂停'),
    ('← / →', '后退/前进 10 秒'),
    ('↑ / ↓', '音量 +10% / -10%'),
    (', / .', '播放速度 -0.25 / +0.25'),
    ('[ / ]', '音调 -1 / +1'),
    ('1 / 2 / 3', '人声音量 100% / 50% / 0%'),
    ('z', '设置起点'),
  ];

  const _HelpButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModal(
          context: context,
          builder: (context) => AlertDialog(
            title: '快捷键'.asText(),
            content: _shortcutItems
                .map((e) {
                  final (keys, action) = e;
                  return [
                    _shortcutKeyChip(context, keys),
                    const SizedBox(width: 10),
                    Expanded(child: Text(action)),
                  ].toRow(crossAxisAlignment: .start);
                })
                .toList()
                .toColumn(
                  mainAxisSize: .min,
                  separator: const SizedBox(height: 8.0),
                )
                .constrained(maxWidth: 420.0),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
      icon: Icon(Icons.question_mark),
    );
  }

  Widget _shortcutKeyChip(BuildContext context, String keys) {
    final colors = Theme.of(context).colorScheme;
    return Text(
          keys,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        )
        .padding(horizontal: 10.0, vertical: 4.0)
        .decorated(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        );
  }
}
