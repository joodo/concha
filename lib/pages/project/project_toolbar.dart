import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../play_controller.dart';
import 'expansible_button.dart';

class _TogglePlayIntent extends Intent {}

class ProjectToolbar extends StatelessWidget {
  const ProjectToolbar({required this.playController, super.key});

  final PlayController playController;

  @override
  Widget build(BuildContext context) {
    final content =
        [
              ListenableBuilder(
                listenable: playController.isPlayNotifier,
                builder: (context, child) => FilledButton(
                  onPressed: Actions.handler(context, _TogglePlayIntent()),
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(18.0),
                  ),
                  child: Icon(
                    playController.isPlayNotifier.value
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
              const SizedBox(width: 8.0),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isExpanded = constraints.maxWidth < 700.0;
                  return [
                    ValueListenableBuilder(
                      valueListenable: playController.volumeNotifier,
                      builder: (context, volumn, child) => ExpansibleButton(
                        isExpanded: isExpanded,
                        icon: Icon(
                          Icons.volume_up,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        value: volumn,
                        labelStringBuilder: (value) =>
                            '${(value * 100).round()} %',
                        divisions: 100,
                        onChanged: playController.setVolume,
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: playController.speedNotifier,
                      builder: (context, speed, child) => ExpansibleButton(
                        isExpanded: isExpanded,
                        icon: Image.asset(
                          'assets/icons/metronome.png',
                          width: 24.0,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        value: speed,
                        min: 0.25,
                        max: 2.0,
                        labelStringBuilder: (value) => 'x $value',
                        divisions: 7,
                        onChanged: playController.setSpeed,
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: playController.pitchNotifier,
                      builder: (context, pitch, child) => ExpansibleButton(
                        isExpanded: isExpanded,
                        icon: Image.asset(
                          'assets/icons/diapason.png',
                          width: 24.0,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        value: pitch.toDouble(),
                        min: -7,
                        max: 7,
                        labelStringBuilder: (value) {
                          final pitch = value.round();
                          final mark = switch (pitch) {
                            0 => '♮',
                            < 0 => '♭',
                            > 0 => '♯',
                            _ => '?',
                          };
                          return '[$pitch] $mark';
                        },
                        divisions: 14,
                        onChanged: (value) =>
                            playController.setPitch(value.round()),
                      ),
                    ),
                  ].toRow(separator: const SizedBox(width: 12));
                },
              ).flexible(),
              ListenableBuilder(
                listenable: playController.positionNotifier,
                builder: (context, child) => Text(
                  '${_formatDuration(playController.positionNotifier.value)} / ${_formatDuration(playController.duration)}',
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
    if (playController.isPlayNotifier.value) {
      return playController.pause();
    } else {
      return playController.playFromStartPoint();
    }
  }
}
