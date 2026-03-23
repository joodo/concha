import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/waveform/waveform.dart';
import '/widgets/setting_button.dart';
import 'business.dart';
import 'project_lyric_section.dart';
import 'providers.dart';
import 'actions.dart';
import 'project_toolbar.dart';

class ProjectPage extends StatelessWidget {
  const ProjectPage({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final bodyContent = [
      ProjectLyricSection().expanded(),
      Builder(
            builder: (context) {
              return Waveform(
                playController: context.read<PlayController>(),
                waveformController: context.read<WavefromController>(),
              );
            },
          )
          .backgroundColor(Theme.of(context).colorScheme.surfaceContainerLow)
          .padding(all: 12.0)
          .constrained(height: 200.0),
      ProjectToolbar(),
    ].toColumn();

    final content = Scaffold(
      appBar: AppBar(
        title: _title.asText(),
        notificationPredicate: (notification) => false,
        actions: [const _HelpButton(), const SettingButton()],
        actionsPadding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      body: Consumer<InitStatus?>(
        builder: (context, status, child) => status == null
            ? CircularProgressIndicator().center()
            : status is InitFailed
            ? Text(
                status.message,
                style: Theme.of(context).textTheme.titleMedium,
              ).center()
            : bodyContent,
      ),
    );

    final body = content.projectBusiness().projectActions().projectProviders(
      project: project,
    );

    return FutureBuilder(
      future: ColorScheme.fromImageProvider(
        provider: FileImage(File(project.path.cover)),
      ),
      initialData: Theme.of(context).colorScheme,
      builder: (context, snapshot) => Theme(
        data: Theme.of(context).copyWith(colorScheme: snapshot.data),
        child: body,
      ),
    );
  }

  String get _title {
    final data = project.metadata;
    final title = data.title;
    final suffix = data.artist == null ? '' : ' - ${data.artist}';
    return '$title$suffix';
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
    final colors = Theme.of(context).colorScheme;
    return Text(
          keys,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        )
        .padding(horizontal: 10.0, vertical: 4.0)
        .decorated(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        );
  }
}
