import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';

import '/audio_sep/audio_sep.dart';
import '/play_controller/play_controller.dart';
import '/preferences/preferences.dart';
import '/projects/projects.dart';
import '/utils/utils.dart';
import '/waveform/waveform.dart';

import '../widgets/theme_from_image.dart';

import 'actions.dart';
import 'project_actions_menu.dart';
import 'project_lyric_section.dart';
import 'project_toolbar.dart';
import 'riverpod.dart';

class ProjectPage extends HookConsumerWidget {
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create project summary
    useEffect(() {
      runAfterBuild(() => ref.projectNotifier!.generateSummaryIfAbsent());
      return null;
    }, []);

    // Seprate audio
    ref.listen(sepAudioEventProvider(ref.projectId!), (previous, next) async {
      if (next.hasError) {
        debugPrint('Failed to load sep audio: ${next.error}');
      }
      if (!next.hasValue) return;

      final event = next.value!;
      if (event is MvsepCompletedEvent) {
        final playController = await ref.read(
          playControllerProvider(ref.projectId!).future,
        );
        await playController.setSeparatedAudio(
          event.vocalPath,
          event.instruPath,
        );
        await playController.setSeparateMode(true);
      }
    });

    late final PlayController playController;
    switch (ref.watch(playControllerProvider(ref.projectId!))) {
      case AsyncLoading<PlayController>():
        return CircularProgressIndicator().center();
      case AsyncError<PlayController>(:final error):
        return Text(
          error.toString(),
          style: context.textStyles.titleMedium,
        ).center();
      case AsyncData<PlayController>(:final value):
        playController = value;
    }

    final expertMode = ref.watch(preferenceProvider<bool>(.expertMode))!;

    final bgSection = Consumer(
      builder: (context, ref, child) {
        final data = ref.watch(projectCoverBytesProvider(ref.projectId!)).value;
        return data == null
            ? const SizedBox.shrink()
            : Image.memory(data, fit: .cover);
      },
    );
    final lyricSection = [
      bgSection,
      SafeArea(
            child: [
              ProjectLyricSection().expanded(),
              if (!expertMode) _LinarBar().padding(bottom: 8.0),
            ].toColumn(separator: 12.0.asHeight()),
          )
          .backgroundBlur(10.0)
          .backgroundColor(context.colors.surfaceContainerLow.withAlpha(200)),
    ].toStack(fit: .expand);

    final bodyContent = [
      lyricSection.expanded(),
      if (expertMode) _WaveformBar(),
    ].toColumn(separator: 12.0.asHeight());

    final appBar = AppBar(
      title: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final title =
              ref.watch(
                ref.projectProvider!.select(
                  (p) => p.value?.metadata.displayTitle,
                ),
              ) ??
              '';
          return title.asText();
        },
      ),
      centerTitle: false,
      actions: [const ProjectActionsMenu(), 8.0.asWidth()],
      backgroundColor: Colors.transparent,
      notificationPredicate: (notification) => false,
    );

    final scaffoldWrap = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
        child: ProjectToolbar(playController: playController),
      ),
      body: bodyContent,
    );

    final themeBuilder = Consumer(
      builder: (context, ref, child) {
        final data = ref.watch(projectCoverBytesProvider(ref.projectId!)).value;
        return ThemeFromImage(data: data, child: child!);
      },
      child: scaffoldWrap,
    );

    return ProjectActions(child: themeBuilder);
  }
}

class _LinarBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playControllerAsync = ref.watch(
      playControllerProvider(ref.projectId!),
    );
    if (!playControllerAsync.hasValue) return const SizedBox.shrink();

    final controller = playControllerAsync.requireValue;
    return ValueListenableBuilder(
      valueListenable: controller.positionNotifier,
      builder: (context, position, child) {
        return Slider(
          year2023: false,
          max: controller.duration.inMilliseconds.toDouble(),
          value: position.inMilliseconds.toDouble(),
          onChanged: (value) =>
              controller.positionNotifier.value = value.round().milliseconds,
        );
      },
    );
  }
}

class _WaveformBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playController = ref.watch(playControllerProvider(ref.projectId!));
    if (!playController.hasValue) return const SizedBox.shrink();

    final waveformController = ref.watch(waveformControllerProvider);
    return Waveform(
          playController: playController.requireValue,
          waveformController: waveformController,
        )
        .backgroundColor(context.colors.surfaceContainerLow)
        .constrained(height: 200.0);
  }
}
