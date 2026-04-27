import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';

import '/generated/l10n.dart';
import '/icon_font/icon_font.dart';
import '/lyric/lyric.dart';
import '/mvsep/riverpod.dart';
import '/play_controller/play_controller.dart';
import '/preferences/preferences.dart';
import '/projects/projects.dart';
import '/shortcuts/shortcuts.dart';
import '/utils/utils.dart';

import '../widgets/play_progress_label.dart';
import '../widgets/popup_widget.dart';

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
              icon: Icon(UiIcons.metronome),
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
                  icon: Icon(UiIcons.diapason),
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

    final expertMode = ref.watch(preferenceProvider<bool>(.expertMode))!;
    return [
      toggleButton,
      if (expertMode) loopButton,
      attachButton,
      stopButton,
      8.0.asWidth(),
      tunings.flexible(),
      PlayProgressLabel(controller: playController),
    ].toRow(separator: 8.0.asWidth());
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
              icon: Icon(UiIcons.mixer),
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
    final sepPathProvider = separationPathProvider(ref.projectId!);
    final sepPathAsync = ref.watch(sepPathProvider);

    final separateModeNotifier = playController.separateModeNotifier;

    return ValueListenableBuilder(
      valueListenable: separateModeNotifier,
      builder: (context, isSeparated, child) {
        return [
          SwitchListTile(
            value: isSeparated,
            title: S.of(context).vocalIsolation.asText(),
            onChanged: sepPathAsync.hasValue
                ? (value) => separateModeNotifier.value = value
                : null,
          ),
          switch (sepPathAsync) {
            AsyncLoading(:final progress) => _buildProgressingContent(
              context,
              progress: progress as double?,
            ),
            AsyncData() => _buildContent(context, isSeparated: isSeparated),
            AsyncError() => _buildErrorContent(
              context,
              retry: () {
                ref.invalidate(sepPathProvider, asReload: true);
              },
            ),
          },
        ].toColumn(separator: const SizedBox(height: 16.0));
      },
    );
  }

  Widget _buildContent(BuildContext context, {required bool isSeparated}) {
    return [
      [
        Icon(UiIcons.microphone).padding(left: 12.0),
        ValueListenableBuilder(
          valueListenable: playController.vocalVolumeNotifier,
          builder: (context, volume, child) => Slider(
            value: volume,
            onChanged: isSeparated ? playController.setVocalVolume : null,
          ),
        ),
      ].toRow(mainAxisAlignment: .center),
      [
        Icon(UiIcons.guitar).padding(left: 12.0),
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

  Widget _buildProgressingContent(BuildContext context, {double? progress}) {
    return [
          S.of(context).processing.asText(),
          CircularProgressIndicator(value: progress),
        ]
        .toColumn(
          mainAxisAlignment: .center,
          separator: const SizedBox(height: 8.0),
        )
        .expanded();
  }

  Widget _buildErrorContent(BuildContext context, {VoidCallback? retry}) {
    return [
          S.of(context).failedToLoadSeparationAudio.asText(),
          TextButton(onPressed: retry, child: S.of(context).retry.asText()),
        ]
        .toColumn(
          mainAxisAlignment: .center,
          separator: const SizedBox(height: 8.0),
        )
        .expanded();
  }
}
