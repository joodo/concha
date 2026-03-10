import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../models/models.dart';
import '../../play_controller.dart';
import '../../waveform/waveform_controller.dart';
import '../../utils/utils.dart';
import '../../waveform/waveform.dart';
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

  @override
  void initState() {
    super.initState();
    _playController = PlayController(audioPath: widget.project.audioPath);
    _wavefromController = WavefromController();
    _initPlayer();
  }

  @override
  void dispose() {
    _playController.dispose();
    _wavefromController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title.asText(),
        notificationPredicate: (notification) => false,
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
              ProjectToolbar(playController: _playController),
            ].toColumn(),
    );
  }

  Future<void> _initPlayer() async {
    try {
      await _playController.initialize();

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

  String get _title {
    final data = widget.project.metadata;
    final title = data.title;
    final suffix = data.artist == null ? '' : ' - ${data.artist}';
    return '$title$suffix';
  }
}
