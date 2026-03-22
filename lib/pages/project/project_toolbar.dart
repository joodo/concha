import 'package:concha/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../services/mvsep_separation_service.dart';
import '../../services/play_controller.dart';
import 'expansible_button.dart';

class _TogglePlayFromStartIntent extends Intent {
  const _TogglePlayFromStartIntent();
}

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

class _SetVocalVolumeIntent extends Intent {
  final double volume;
  const _SetVocalVolumeIntent(this.volume);
}

class _MarkStartPoint extends Intent {
  const _MarkStartPoint();
}

class ProjectToolbar extends StatelessWidget {
  const ProjectToolbar({required this.playController, super.key});

  final PlayController playController;

  @override
  Widget build(BuildContext context) {
    final content =
        [
              ValueListenableBuilder(
                valueListenable: playController.isPlayNotifier,
                builder: (context, isPlaying, child) => IconButton.filled(
                  onPressed: Actions.handler(
                    context,
                    const _TogglePlayFromStartIntent(),
                  ),
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.slow_motion_video,
                    size: 32,
                  ),
                  tooltip: isPlaying ? '暂停' : '从起点播放',
                ),
              ),
              IconButton(
                onPressed: playController.play,
                tooltip: '播放',
                icon: const Icon(Icons.play_arrow_rounded),
              ),
              IconButton(
                onPressed: playController.stop,
                tooltip: '停止',
                icon: const Icon(Icons.stop_rounded),
              ),
              const SizedBox(width: 8.0),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isExpanded = constraints.maxWidth >= 940.0;
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
                    ).tooltip('音量'),
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
                    ).tooltip('速度'),
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
                      ).tooltip('音调'),
                    ),
                    _createSeparateSlider(),
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
        _TogglePlayFromStartIntent: CallbackAction<_TogglePlayFromStartIntent>(
          onInvoke: (intent) => _togglePlay(fromStart: true),
        ),
        _TogglePlayIntent: CallbackAction<_TogglePlayIntent>(
          onInvoke: (intent) => _togglePlay(),
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
        _SetVocalVolumeIntent: CallbackAction<_SetVocalVolumeIntent>(
          onInvoke: (intent) {
            playController.setSeparateMode(true);
            playController.setVocalVolume(intent.volume);
            return null;
          },
        ),
        _MarkStartPoint: CallbackAction<_MarkStartPoint>(
          onInvoke: (intent) {
            final position = playController.positionNotifier.value;
            playController.setStartPosition(position);
            return null;
          },
        ),
      },
      child: Shortcuts(
        shortcuts: {
          SingleActivator(LogicalKeyboardKey.space):
              const _TogglePlayFromStartIntent(),
          SingleActivator(LogicalKeyboardKey.space, shift: true):
              const _TogglePlayIntent(),
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
          SingleActivator(LogicalKeyboardKey.digit1): _SetVocalVolumeIntent(
            1.0,
          ),
          SingleActivator(LogicalKeyboardKey.digit2): _SetVocalVolumeIntent(
            0.5,
          ),
          SingleActivator(LogicalKeyboardKey.digit3): _SetVocalVolumeIntent(0),
          SingleActivator(LogicalKeyboardKey.keyZ): _MarkStartPoint(),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  Widget _createSeparateSlider() {
    return Consumer<Stream<MvsepTaskEvent>?>(
      builder: (context, taskStream, child) {
        if (taskStream == null) {
          return ValueListenableBuilder(
            valueListenable: playController.separateModeNotifier,
            builder: (context, isSeparated, child) => [
              IconButton.filled(
                onPressed: () => playController.setSeparateMode(!isSeparated),
                isSelected: isSeparated,
                tooltip: '伴奏模式：${isSeparated ? "开" : "关"}',
                icon: Icon(
                  isSeparated ? Icons.mic_external_on : Icons.mic_external_off,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: playController.vocalVolumeNotifier,
                builder: (context, volume, child) => Slider(
                  value: volume,
                  onChanged: isSeparated ? playController.setVocalVolume : null,
                ),
              ),
            ].toRow(),
          );
        }

        return StreamBuilder(
          stream: taskStream,
          builder: (context, snapshot) {
            String getMessage(MvsepTaskEvent? event) {
              switch (event) {
                case null:
                case MvsepInitEvent():
                  return '正在初始化服务';

                case MvsepLocalQueuedEvent(:final localQueuePosition):
                  return '正在等待其他歌曲 (还有 $localQueuePosition 项';

                case MvsepLocalRunningEvent():
                  return '正在执行';

                case MvsepUploadingEvent(
                  :final uploadedBytes,
                  :final totalBytes,
                ):
                  final percent = (uploadedBytes / totalBytes).asPercent;
                  return '正在上传 ($percent%)\n'
                      '${uploadedBytes.asByteSize} / ${totalBytes.asByteSize}';

                case MvsepRemoteQueuedEvent(:final remoteCurrentOrder):
                  return '正在排队 (还有 $remoteCurrentOrder 人)';

                case MvsepRemoteProcessingEvent():
                  return '正在分离人声和伴奏';

                case MvsepDownloadingEvent(
                  :final vocalDownloadedBytes,
                  :final vocalFileBytes,
                  :final instruDownloadedBytes,
                  :final instruFileBytes,
                ):
                  final downloaded =
                      instruDownloadedBytes + vocalDownloadedBytes;
                  if (instruFileBytes == null || vocalFileBytes == null) {
                    return '正在下载 (已下载${downloaded.asByteSize})';
                  }

                  final total = instruFileBytes + vocalFileBytes;
                  final percent = (downloaded / total).asPercent;
                  return '正在下载 ($percent%)\n'
                      '${vocalDownloadedBytes.asByteSize} / ${vocalFileBytes.asByteSize}'
                      '${instruDownloadedBytes.asByteSize} / ${instruFileBytes.asByteSize}';

                case MvsepCompletedEvent():
                  return '生成成功！正在加载';
                case MvsepFailedEvent(:final phase, :final error):
                  return '失败阶段：$phase\n原因：$error';
              }
            }

            final message = getMessage(snapshot.data);
            return Tooltip(
              message: message,
              child: Text(
                snapshot.data is MvsepFailedEvent ? '生成伴奏失败' : '正在生成伴奏……',
              ),
            );
          },
        );
      },
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

  Future<void> _togglePlay({bool fromStart = false}) {
    if (playController.isPlayNotifier.value) {
      return playController.pause();
    } else {
      return fromStart
          ? playController.playFromStartPoint()
          : playController.play();
    }
  }
}
