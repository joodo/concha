import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../models/models.dart';
import '../../play_controller.dart';
import '../../waveform/waveform_controller.dart';
import '../../waveform/waveform.dart';

class TogglePlayIntent extends Intent {}

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
      appBar: AppBar(title: Text(_displayName)),
      body: [
        _buildWaveformSection(context).expanded(),
        _buildToolbarSection(context),
      ].toColumn(),
    );
  }

  Widget _buildWaveformSection(BuildContext context) {
    if (_isPreparing) return CircularProgressIndicator().center();

    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: Theme.of(context).textTheme.titleMedium,
      ).center();
    }

    return Waveform(
          playController: _playController,
          waveformController: _wavefromController,
        )
        .backgroundColor(Theme.of(context).colorScheme.surfaceContainerLow)
        .padding(all: 12.0);
  }

  Widget _buildToolbarSection(BuildContext context) {
    final content =
        [
              ListenableBuilder(
                listenable: _playController,
                builder: (context, child) => FilledButton.tonal(
                  onPressed: _togglePlayPause,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(18.0),
                  ),
                  child: Icon(
                    _playController.isPlaying
                        ? Icons.pause_rounded
                        : Icons.slow_motion_video,
                    size: 32,
                  ),
                ),
              ),
              IconButton(
                onPressed: _play,
                icon: const Icon(Icons.play_arrow_rounded),
              ),
              IconButton(
                onPressed: _stop,
                icon: const Icon(Icons.stop_rounded),
                tooltip: '停止',
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: _playController,
                builder: (context, child) => Text(
                  '${_formatDuration(_playController.position)} / ${_formatDuration(_playController.duration)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ]
            .toRow(separator: const SizedBox(width: 8.0))
            .padding(horizontal: 12.0, bottom: 12.0);

    return Actions(
      actions: {
        TogglePlayIntent: CallbackAction<TogglePlayIntent>(
          onInvoke: (intent) => _togglePlayPause(),
        ),
      },
      child: Shortcuts(
        shortcuts: {
          SingleActivator(LogicalKeyboardKey.space): TogglePlayIntent(),
        },
        child: Focus(autofocus: true, child: content),
      ),
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

  Future<void> _togglePlayPause() async {
    if (_isPreparing ||
        _errorMessage != null ||
        !_playController.isInitialized) {
      return;
    }

    try {
      if (_playController.isPlaying) {
        await _playController.pause();
      } else {
        await _playController.playFromStartPoint();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '音频播放器初始化失败，请重启应用后重试';
      });
      rethrow;
    }
  }

  Future<void> _play() async {
    if (_isPreparing ||
        _errorMessage != null ||
        !_playController.isInitialized) {
      return;
    }

    try {
      await _playController.play();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '无法从起始点开始播放';
      });
      rethrow;
    }
  }

  Future<void> _stop() async {
    if (!_playController.isInitialized) {
      return;
    }

    try {
      await _playController.stop();
    } catch (_) {
      rethrow;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }

  String get _displayName {
    final segments = Uri.file(widget.project.audioPath).pathSegments;
    if (segments.isEmpty) {
      return widget.project.audioPath;
    }
    return segments.last;
  }
}
