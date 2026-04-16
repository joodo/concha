import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';

import '/audio_sep/audio_sep.dart';
import '/play_controller/play_controller.dart';
import '/projects/projects.dart';
import '/utils/utils.dart';
import '/waveform/waveform.dart';
import '/widgets/settings.dart';
import '/widgets/theme_from_image.dart';

import 'actions.dart';
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

    final bgSection = Consumer(
      builder: (context, ref, child) {
        final coverPath =
            ref.watch(
              ref.projectProvider!.select((p) => p.value?.path.cover),
            ) ??
            '';
        final coverFile = File(coverPath);
        return FutureBuilder(
          future: coverFile.exists(),
          builder: (context, snapshot) => snapshot.data == true
              ? Image.file(coverFile, fit: .cover)
              : const SizedBox.shrink(),
        );
      },
    );
    final lyricSection = [
      bgSection,
      SafeArea(child: ProjectLyricSection())
          .backgroundBlur(10.0)
          .backgroundColor(context.colors.surfaceContainerLow.withAlpha(200)),
    ].toStack(fit: .expand);

    final bodyContent = [
      lyricSection.expanded(),
      Waveform(
            playController: playController,
            waveformController: ref.watch(waveformControllerProvider),
          )
          .backgroundColor(context.colors.surfaceContainerLow)
          .padding(top: 12.0)
          .constrained(height: 200.0),
    ].toColumn();

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
      actions: [const SettingButton(), 8.0.asWidth()],
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
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
        final coverPath =
            ref.watch(
              ref.projectProvider!.select((p) => p.value?.path.cover),
            ) ??
            '';
        return ThemeFromImage(path: coverPath, child: child!);
      },
      child: scaffoldWrap,
    );

    return ProjectActions(child: themeBuilder);
  }
}
