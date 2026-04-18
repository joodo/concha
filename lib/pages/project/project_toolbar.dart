import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';

import '/audio_sep/audio_sep.dart';
import '/generated/l10n.dart';
import '/lyric/lyric.dart';
import '/play_controller/play_controller.dart';
import '/preferences/preferences.dart';
import '/projects/projects.dart';
import '/shortcuts/shortcuts.dart';
import '/utils/utils.dart';
import '/widgets/popup_widget.dart';

import 'actions.dart';
import 'expansible_button.dart';

class ProjectToolbar extends ConsumerWidget {
  const ProjectToolbar({super.key, required this.playController});

  final PlayController playController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loopProvider = preferenceProvider<bool>(.playLoop);
    final toggleButton = Consumer(
      builder: (context, ref, child) {
        final isLoop = ref.watch(loopProvider)!;

        final tooltipText = playController.isPlayNotifier.value
            ? S.of(context).pause
            : isLoop
            ? S.of(context).playFromStartPoint
            : S.of(context).play;

        return ValueListenableBuilder(
          valueListenable: playController.isPlayNotifier,
          builder: (context, isPlaying, child) => IconButton.filled(
            onPressed: Actions.handler(context, const TogglePlayIntent()),
            icon: Icon(
              playController.isPlayNotifier.value
                  ? Icons.pause_rounded
                  : isLoop
                  ? Icons.slow_motion_video
                  : Icons.play_arrow,
              size: 32,
            ),
            tooltip: ref.tooltipWithShortcuts(tooltipText, [.togglePlay]),
          ),
        );
      },
    );

    final loopButton = Consumer(
      builder: (context, ref, child) {
        return IconButton.outlined(
          isSelected: ref.watch(loopProvider)!,
          onPressed: ref.read(loopProvider.notifier).toggle,
          tooltip: S.of(context).playFromStartPoint,
          icon: const Icon(Icons.repeat),
        );
      },
    );

    final attachButton = Consumer(
      builder: (context, ref, child) {
        final attachToLyricProvider = preferenceProvider<bool>(.attachToLyric);
        final attachNotifier = ref.watch(attachToLyricProvider);

        final hasLyric = ref.watch(
          lyricProvider(
            ref.projectId!,
            isTranslate: false,
          ).select((asyncValue) => asyncValue.value != null),
        );

        return IconButton.outlined(
          onPressed: hasLyric
              ? ref.read(attachToLyricProvider.notifier).toggle
              : null,
          tooltip: S.of(context).attachToLyric,
          isSelected: attachNotifier,
          icon: const Icon(Icons.my_location),
        );
      },
    );

    final stopButton = IconButton(
      onPressed: playController.stop,
      tooltip: S.of(context).stop,
      icon: const Icon(Icons.stop_rounded),
    );

    final tunings = LayoutBuilder(
      builder: (context, constraints) {
        final isExpanded = constraints.maxWidth >= 750.0;
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
              labelStringBuilder: (value) => '${(value * 100).round()} %',
              divisions: 100,
              onChanged: playController.setVolume,
            ),
          ).tooltip(
            ref.tooltipWithShortcuts(S.of(context).volume, [
              .volumeDown,
              .volumeUp,
            ]),
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
          ).tooltip(
            ref.tooltipWithShortcuts(S.of(context).playbackRate, [
              .speedDown,
              .speedUp,
            ]),
          ),
          ValueListenableBuilder(
            valueListenable: playController.pitchNotifier,
            builder: (context, pitch, child) =>
                ExpansibleButton(
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
                  onChanged: (value) => playController.setPitch(value.round()),
                ).tooltip(
                  ref.tooltipWithShortcuts(S.of(context).pitch, [
                    .pitchDown,
                    .pitchUp,
                  ]),
                ),
          ),
          _MixTableButton(playController: playController),
        ].toRow(separator: 12.0.asWidth());
      },
    );

    return [
      toggleButton,
      loopButton,
      attachButton,
      stopButton,
      8.0.asWidth(),
      tunings.flexible(),
      _createDurationLabel(),
    ].toRow(separator: 8.0.asWidth());
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
}

class _MixTableButton extends HookWidget {
  const _MixTableButton({required this.playController});

  final PlayController playController;

  @override
  Widget build(BuildContext context) {
    final isShowing = useState(false);

    final link = LayerLink();
    return PopupWidget(
      showing: isShowing.value,
      popupBuilder: (context) => Material(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        child: Consumer(
          builder: _popupContentBuilder,
        ).constrained(width: 240.0, height: 160.0).padding(vertical: 12.0),
      ),
      layoutBuilder: (context, popup) => GestureDetector(
        behavior: .opaque,
        onTap: () => isShowing.value = false,
        child: UnconstrainedBox(
          child: CompositedTransformFollower(
            link: link,
            targetAnchor: .topCenter,
            followerAnchor: .bottomCenter,
            offset: Offset(0, -16.0),
            child: popup,
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: link,
        child: ValueListenableBuilder(
          valueListenable: playController.separateModeNotifier,
          builder: (context, isSep, child) => Consumer(
            builder: (context, ref, child) {
              return child!.tooltip(
                ref.tooltipWithShortcuts(S.of(context).mixTable, [
                  .mixPreset1,
                  .mixPreset2,
                  .mixPreset3,
                  .mixPreset4,
                ]),
              );
            },
            child: IconButton.outlined(
              onPressed: () => isShowing.value = true,
              isSelected: isSep,
              icon: Image.asset(
                'assets/icons/mixing-table.png',
                width: 20.0,
                color: context.colors.onSurfaceVariant,
              ),
              selectedIcon: Image.asset(
                'assets/icons/mixing-table-fill.png',
                width: 20.0,
                color: context.colors.onInverseSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _popupContentBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    final event = ref.watch(sepAudioEventProvider(ref.projectId!)).value;

    final separateModeNotifier = playController.separateModeNotifier;

    final isSepFileReady = event is MvsepCompletedEvent;
    return ValueListenableBuilder(
      valueListenable: separateModeNotifier,
      builder: (context, isSeparated, child) {
        return [
          SwitchListTile(
            value: isSeparated,
            title: S.of(context).vocalIsolation.asText(),
            onChanged: isSepFileReady
                ? (value) => separateModeNotifier.value = value
                : null,
          ),
          isSepFileReady
              ? _buildContent(context, isSeparated: isSeparated)
              : _buildProgressingContent(context, _getMessage(context, event)),
        ].toColumn(separator: const SizedBox(height: 16.0));
      },
    );
  }

  Widget _buildContent(BuildContext context, {required bool isSeparated}) {
    return [
      [
        Image.asset(
          'assets/icons/singing.png',
          width: 24.0,
          color: context.colors.onSurfaceVariant,
        ).padding(left: 12.0),
        ValueListenableBuilder(
          valueListenable: playController.vocalVolumeNotifier,
          builder: (context, volume, child) => Slider(
            value: volume,
            onChanged: isSeparated ? playController.setVocalVolume : null,
          ),
        ),
      ].toRow(mainAxisAlignment: .center),
      [
        Image.asset(
          'assets/icons/drum.png',
          width: 24.0,
          color: context.colors.onSurfaceVariant,
        ).padding(left: 12.0),
        ValueListenableBuilder(
          valueListenable: playController.instruVolumeNotifier,
          builder: (context, volume, child) => Slider(
            value: volume,
            onChanged: isSeparated ? playController.setInstruVolume : null,
          ),
        ),
      ].toRow(mainAxisAlignment: .center),
    ].toColumn();
  }

  Widget _buildProgressingContent(BuildContext context, String message) {
    return [S.of(context).processing.asText(), message.asText()]
        .toColumn(
          mainAxisAlignment: .center,
          separator: const SizedBox(height: 8.0),
        )
        .expanded();
  }

  String _getMessage(BuildContext context, MvsepTaskEvent? event) {
    switch (event) {
      case null:
      case MvsepInitEvent():
        return S.of(context).initiatingService;

      case MvsepLocalRunningEvent():
        return S.of(context).startingProgress;

      case MvsepUploadingEvent(:final uploadedBytes, :final totalBytes):
        final percent = (uploadedBytes / totalBytes).asPercent;
        return '${S.of(context).uploading} ($percent%)\n'
            '${uploadedBytes.asByteSize} / ${totalBytes.asByteSize}';

      case MvsepRemoteQueuedEvent(:final remoteCurrentOrder):
        return S.of(context).queueStatus(remoteCurrentOrder ?? 0);

      case MvsepRemoteProcessingEvent():
        return S.of(context).separatingStatus;

      case MvsepDownloadingEvent(
        :final vocalDownloadedBytes,
        :final vocalFileBytes,
        :final instruDownloadedBytes,
        :final instruFileBytes,
      ):
        final downloaded = instruDownloadedBytes + vocalDownloadedBytes;
        if (instruFileBytes == null || vocalFileBytes == null) {
          return '${S.of(context).downloadingStatus} ${S.of(context).downloadedBytes(downloaded.asByteSize)}';
        }

        final total = instruFileBytes + vocalFileBytes;
        final percent = (downloaded / total).asPercent;
        return '${S.of(context).downloadingStatus} ($percent%)\n'
            '${vocalDownloadedBytes.asByteSize} / ${vocalFileBytes.asByteSize}\n'
            '${instruDownloadedBytes.asByteSize} / ${instruFileBytes.asByteSize}';

      case MvsepCompletedEvent():
        return S.of(context).loadingAfterSeparatedStatus;
      case MvsepFailedEvent(:final phase, :final error):
        return S.of(context).phaseFailedStatus(phase, error);
    }
  }
}
