import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../play_controller.dart';

class _TogglePlayIntent extends Intent {}

class ProjectToolbar extends StatelessWidget {
  const ProjectToolbar({required this.playController, super.key});

  final PlayController playController;

  @override
  Widget build(BuildContext context) {
    final content =
        [
              ListenableBuilder(
                listenable: playController,
                builder: (context, child) => FilledButton.tonal(
                  onPressed: Actions.handler(context, _TogglePlayIntent()),
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(18.0),
                  ),
                  child: Icon(
                    playController.isPlaying
                        ? Icons.pause_rounded
                        : Icons.slow_motion_video,
                    size: 32,
                  ),
                ),
              ),
              IconButton(
                onPressed: playController.play,
                icon: const Icon(Icons.play_arrow_rounded),
              ),
              IconButton(
                onPressed: playController.stop,
                icon: const Icon(Icons.stop_rounded),
                tooltip: '停止',
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: playController,
                builder: (context, child) => Text(
                  '${_formatDuration(playController.position)} / ${_formatDuration(playController.duration)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ]
            .toRow(separator: const SizedBox(width: 8.0))
            .padding(horizontal: 12.0, bottom: 12.0);

    return Actions(
      actions: {
        _TogglePlayIntent: CallbackAction<_TogglePlayIntent>(
          onInvoke: (intent) => _togglePlayPause(),
        ),
      },
      child: Shortcuts(
        shortcuts: {
          SingleActivator(LogicalKeyboardKey.space): _TogglePlayIntent(),
        },
        child: Focus(autofocus: true, child: content),
      ),
    );
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

  Future<void> _togglePlayPause() {
    if (playController.isPlaying) {
      return playController.pause();
    } else {
      return playController.playFromStartPoint();
    }
  }
}
