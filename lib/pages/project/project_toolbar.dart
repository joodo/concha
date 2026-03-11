import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../services/play_controller.dart';
import 'expansible_button.dart';

class _TogglePlayIntent extends Intent {
  const _TogglePlayIntent();
}

class _DeltaPositionIntent extends Intent {
  const _DeltaPositionIntent(this.delta);
  final Duration delta;
}

class _DeltaVolumeIntent extends Intent {
  const _DeltaVolumeIntent(this.delta);
  final double delta;
}

class _DeltaSpeedIntent extends Intent {
  const _DeltaSpeedIntent(this.delta);
  final double delta;
}

class _DeltaPitchIntent extends Intent {
  const _DeltaPitchIntent(this.delta);
  final int delta;
}

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
                  onPressed: Actions.handler(
                    context,
                    const _TogglePlayIntent(),
                  ),
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
              _createDurationLabel(),
            ]
            .toRow(separator: const SizedBox(width: 8.0))
            .padding(horizontal: 12.0, bottom: 12.0);

    return _createShortcuts(content);
  }

  Widget _createShortcuts(Widget child) {
    return Actions(
      actions: {
        _TogglePlayIntent: CallbackAction<_TogglePlayIntent>(
          onInvoke: (intent) => _togglePlayPause(),
        ),
        _DeltaPositionIntent: CallbackAction<_DeltaPositionIntent>(
          onInvoke: (intent) {
            final current = playController.positionNotifier.value;
            return playController.seekTo(current + intent.delta);
          },
        ),
        _DeltaVolumeIntent: CallbackAction<_DeltaVolumeIntent>(
          onInvoke: (intent) {
            final current = playController.volumeNotifier.value;
            playController.setVolume(current + intent.delta);
            return null;
          },
        ),
        _DeltaSpeedIntent: CallbackAction<_DeltaSpeedIntent>(
          onInvoke: (intent) {
            final current = playController.speedNotifier.value;
            final next = (current + intent.delta).clamp(0.25, 2.0).toDouble();
            playController.setSpeed(next);
            return null;
          },
        ),
        _DeltaPitchIntent: CallbackAction<_DeltaPitchIntent>(
          onInvoke: (intent) {
            final current = playController.pitchNotifier.value;
            final next = (current + intent.delta).clamp(-7, 7);
            playController.setPitch(next);
            return null;
          },
        ),
      },
      child: Shortcuts(
        shortcuts: {
          SingleActivator(LogicalKeyboardKey.space): const _TogglePlayIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): _DeltaVolumeIntent(0.1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _DeltaVolumeIntent(
            -0.1,
          ),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _DeltaPositionIntent(
            Duration(seconds: -10),
          ),
          SingleActivator(LogicalKeyboardKey.arrowRight): _DeltaPositionIntent(
            Duration(seconds: 10),
          ),
          SingleActivator(LogicalKeyboardKey.comma): _DeltaSpeedIntent(-0.25),
          SingleActivator(LogicalKeyboardKey.period): _DeltaSpeedIntent(0.25),
          SingleActivator(LogicalKeyboardKey.bracketLeft): _DeltaPitchIntent(
            -1,
          ),
          SingleActivator(LogicalKeyboardKey.bracketRight): _DeltaPitchIntent(
            1,
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  Widget _createDurationLabel() {
    String formatDuration(Duration duration) {
      final minutes = duration.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final seconds = duration.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final hours = duration.inHours;

      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
      }

      return '$minutes:$seconds';
    }

    return ListenableBuilder(
      listenable: playController.positionNotifier,
      builder: (context, child) => Text(
        '${formatDuration(playController.positionNotifier.value)} / ${formatDuration(playController.duration)}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Future<void> _togglePlayPause() {
    if (playController.isPlayNotifier.value) {
      return playController.pause();
    } else {
      return playController.playFromStartPoint();
    }
  }
}
