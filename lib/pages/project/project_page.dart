import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';

import '/services/services.dart';
import '/utils/utils.dart';
import '/waveform/waveform.dart';
import '/widgets/setting_button.dart';

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
      actions: [const _HelpButton(), const SettingButton()],
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
        return FutureBuilder(
          future: ColorScheme.fromImageProvider(
            provider: FileImage(File(coverPath)),
          ),
          initialData: context.colors,
          builder: (context, snapshot) => Theme(
            data: context.theme.copyWith(colorScheme: snapshot.data),
            child: child!,
          ),
        );
      },
      child: scaffoldWrap,
    );

    return ProjectActions(child: themeBuilder);
  }
}

class _HelpButton extends StatelessWidget {
  static const List<(String, String)> _shortcutItems = [
    ('Space', '播放/暂停'),
    ('← / →', '后退/前进'),
    ('↑ / ↓', '音量 +10% / -10%'),
    (', / .', '播放速度 -0.25 / +0.25'),
    ('[ / ]', '音调 -1 / +1'),
    ('1 / 2 / 3', '人声消除 0% / 60% / 100%'),
    ('4', '人声凸显'),
    ('z', '设置起点'),
    ('s', '朗读当前歌词'),
  ];

  const _HelpButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModal(
          context: context,
          builder: (context) => AlertDialog(
            title: '快捷键'.asText(),
            content: _shortcutItems
                .map((e) {
                  final (keys, action) = e;
                  return [
                    _shortcutKeyChip(context, keys),
                    const SizedBox(width: 10),
                    Expanded(child: Text(action)),
                  ].toRow(crossAxisAlignment: .center);
                })
                .toList()
                .toColumn(
                  mainAxisSize: .min,
                  separator: const SizedBox(height: 8.0),
                )
                .constrained(maxWidth: 420.0),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
      icon: Icon(Icons.question_mark),
    );
  }

  Widget _shortcutKeyChip(BuildContext context, String keys) {
    return Text(
          keys,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        )
        .padding(horizontal: 10.0, vertical: 4.0)
        .decorated(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.colors.outlineVariant),
        );
  }
}
